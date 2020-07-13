#!/usr/bin/env bash

scriptName=${0##*/}

echo; echo "[$scriptName] +----------------------------+"
echo "[$scriptName] | Process BUILD all projects |"
echo "[$scriptName] +----------------------------+"; echo
SOLUTION="$1"
if [ -z "$SOLUTION" ]; then
	echo "[$scriptName] Solution not passed!"
	exit 1
else
	echo "[$scriptName]   SOLUTION       : $SOLUTION"
fi

BUILDNUMBER="$2"
if [ -z "$BUILDNUMBER" ]; then
	echo "[$scriptName] Build Number not passed!"
	exit 2
else
	echo "[$scriptName]   BUILDNUMBER    : $BUILDNUMBER"
fi

REVISION="$3"
if [ -z "$REVISION" ]; then
	REVISION="Revision"
	echo "[$scriptName]   REVISION       : $REVISION (default)"
else
	echo "[$scriptName]   REVISION       : $REVISION"
fi

ACTION="$4"
if [ -z "$ACTION" ]; then
	echo "[$scriptName]   ACTION         : $ACTION"
	BUILDENV='BUILDER'
	echo "[$scriptName]   BUILDENV       : $BUILDENV (default because ACTION not supplied)"
else
	# case insensitive by forcing to uppercase
	testForClean=$(echo "$ACTION" | tr '[a-z]' '[A-Z]')
	if [ "$testForClean" == "CLEAN" ]; then
		echo "[$scriptName]   ACTION         : $ACTION (Build Environment will be set to default)"
		BUILDENV='BUILDER'
		echo "[$scriptName]   BUILDENV       : $BUILDENV (default)"
	else
		BUILDENV="$ACTION"
		echo "[$scriptName]   ACTION         : $ACTION"
		echo "[$scriptName]   BUILDENV       : $BUILDENV (derived from action)"
	fi
fi

# Look for automation root definition
AUTOMATIONROOT="$(dirname $( cd "$(dirname "$0")" ; pwd -P ))"
echo "[$scriptName]   AUTOMATIONROOT : $AUTOMATIONROOT"

AUTOMATIONHELPER="$AUTOMATIONROOT/remote"

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "$scriptName :   SOLUTIONROOT   : "
for directoryName in $(find $(pwd) -mindepth 1 -maxdepth 1 -type d); do
	if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
		SOLUTIONROOT="$directoryName"
	fi
done

if [ -z ${SOLUTIONROOT+x} ]; then
	SOLUTIONROOT="$AUTOMATIONROOT/solution"
	echo "$SOLUTIONROOT (default, project directory containing CDAF.solution not found)"
else
	echo "$SOLUTIONROOT (override $SOLUTIONROOT/CDAF.solution found)"
fi

if [ -f "$SOLUTIONROOT/CDAF.solution" ]; then
	propertiesList=$($AUTOMATIONHELPER/transform.sh "$SOLUTIONROOT/CDAF.solution")
	echo; echo "$propertiesList"
	eval $propertiesList
else
	echo; echo "[$scriptName] CDAF.solution file not found!"; exit 8823
fi

if [ -f "build.sh" ]; then
	echo; echo "[$scriptName] build.sh found in solution root, executing in $(pwd)"; echo
	# Additional properties that are not passed as arguments, but loaded by execute automatically
	echo "PROJECT=$PROJECT" > ./solution.properties
	echo "REVISION=$REVISION" >> ./solution.properties
	echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ./solution.properties
	echo "SOLUTIONROOT=$SOLUTIONROOT" >> ./solution.properties
	./build.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$BUILDENV" "$ACTION"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] $PROJECT Build Failed, exit code = $exitCode."
		exit $exitCode
	fi
fi
	
if [ -f "build.tsk" ]; then

	echo; echo "[$scriptName] build.tsk found in solution root, executing in $(pwd)"; echo
	# Additional properties that are not passed as arguments, explicit load is required
	echo "PROJECT=$PROJECT" > ./solution.properties
	echo "REVISION=$REVISION" >> ./solution.properties
	echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ./solution.properties
	echo "SOLUTIONROOT=$SOLUTIONROOT" >> ./solution.properties
	$AUTOMATIONHELPER/execute.sh "$SOLUTION" "$BUILDNUMBER" "$BUILDENV" "build.tsk" "$ACTION" 2>&1
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] Linear deployment activity ($AUTOMATIONHELPER/execute.sh $SOLUTION $BUILDNUMBER $PROJECT build.tsk) failed! Returned $exitCode"
		exit $exitCode
	fi
fi

customProjectList="$SOLUTIONROOT/buildProjects"

if [ -f "$customProjectList" ]; then
	dirList=$(cat $customProjectList)
else
	dirList=$(find . -mindepth 1 -maxdepth 1 -type d)
fi

# Create a list of projects based on directories containing build script entry point
for folder in $dirList; do
	if [ -f "$folder/build.sh" ] || [ -f "$folder/build.tsk" ]; then
		projectsToBuild+="$folder "
	fi
done

if [ -z "$projectsToBuild" ]; then
	echo; echo "[$scriptName] No projects found, no build action attempted."
else
	echo; echo "[$scriptName]   Projects to process :"; echo
	for projectName in $projectsToBuild; do
		echo "  ${projectName##*/}"
	done

	for projectName in $projectsToBuild; do
		projectName=${projectName##*/}
		echo; echo "[$scriptName] --- BUILD ${projectName} ---"; echo
		cd ${projectName}
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo "[$scriptName] cd ${projectName} failed! Exit code = $exitCode."
			exit $exitCode
		fi

		# Additional properties that are not passed as arguments, but loaded by execute automatically, to use in build.sh, explicit load is required		
		echo "PROJECT=${projectName}" > ../build.properties
		echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ../build.properties
		echo "SOLUTIONROOT=$SOLUTIONROOT" >> ../build.properties

		if [ -f "build.sh" ]; then
		
			./build.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$BUILDENV" "$ACTION"
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "[$scriptName] $projectName Build Failed, exit code = $exitCode."
				exit $exitCode
			fi
			
		else
						
			echo "REVISION=$REVISION" >> ../build.properties
			$AUTOMATIONHELPER/execute.sh "$SOLUTION" "$BUILDNUMBER" "$BUILDENV" "build.tsk" "$ACTION" 2>&1
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "[$scriptName] Linear deployment activity ($AUTOMATIONHELPER/execute.sh $SOLUTION $BUILDNUMBER $projectName build.tsk) failed! Returned $exitCode"
				exit $exitCode
			fi
		fi
		
		cd ..
	
		lastProject=$(echo $projectName)
	
	done
	
	if [ -z $lastProject ]; then
		echo; echo "[$scriptName] No projects found containing build.sh, no build action attempted."
	fi

fi
