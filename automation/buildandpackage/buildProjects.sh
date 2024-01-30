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

export REVISION="$3"
if [ -z "$REVISION" ]; then
	REVISION="Revision"
	echo "[$scriptName]   REVISION       : $REVISION (default)"
else
	echo "[$scriptName]   REVISION       : $REVISION"
fi

ACTION="$4"
if [ -z "$ACTION" ]; then
	echo "[$scriptName]   ACTION         : (not passed)"
else
	echo "[$scriptName]   ACTION         : $ACTION"
fi

echo "[$scriptName]   BUILDENV       : $BUILDENV"

# Look for automation root definition
printf "[$scriptName]   AUTOMATIONROOT : "
if [ ! -z "$AUTOMATIONROOT" ]; then
	echo "$AUTOMATIONROOT (global variable)"
else
	export AUTOMATIONROOT="$(dirname "$( cd "$(dirname "$0")" && pwd )")"
	echo "$AUTOMATIONROOT"
fi

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "[$scriptName]   SOLUTIONROOT   : "
if [ ! -z "$SOLUTIONROOT" ]; then
	echo "$SOLUTIONROOT (global variable)"
else
	for directoryName in $(find $(pwd) -mindepth 1 -maxdepth 1 -type d); do
		if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
			export SOLUTIONROOT="$directoryName"
		fi
	done
	if [ -z "$SOLUTIONROOT" ]; then
		export SOLUTIONROOT="$AUTOMATIONROOT/solution"
		echo "$SOLUTIONROOT (default, project directory containing CDAF.solution not found)"
	else
		echo "$SOLUTIONROOT (override $SOLUTIONROOT/CDAF.solution found)"
	fi
fi

if [ -f "$SOLUTIONROOT/CDAF.solution" ]; then
	propertiesList=$("$CDAF_CORE/transform.sh" "$SOLUTIONROOT/CDAF.solution")
	echo; echo "$propertiesList"
	eval $propertiesList
else
	echo; echo "[$scriptName] CDAF.solution file not found!"; exit 8823
fi

if [ -f "build.sh" ]; then
	echo; echo "[$scriptName] build.sh found in solution root, executing in $(pwd)"; echo
	"./build.sh" "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$BUILDENV" "$ACTION"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] $PROJECT Build Failed, exit code = $exitCode."
		exit $exitCode
	fi
fi
	
if [ -f "build.tsk" ]; then

	echo; echo "[$scriptName] build.tsk found in solution root, executing in $(pwd)"; echo
	"$CDAF_CORE/execute.sh" "$SOLUTION" "$BUILDNUMBER" "$BUILDENV" "build.tsk" "$ACTION" 2>&1
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] Linear deployment activity (\"$CDAF_CORE/execute.sh\" \"$SOLUTION\" \"$BUILDNUMBER\" \"$BUILDENV\" \"build.tsk\" \"$ACTION\") failed! Returned $exitCode"
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
	echo; echo "[$scriptName] No projects found, no build action attempted."; echo
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

		# Additional properties that are not passed as arguments, but loaded as environment variables		
		export PROJECT="${projectName}"

		if [ -f "build.sh" ]; then
		
			./build.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$BUILDENV" "$ACTION"
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "[$scriptName] $projectName Build Failed, exit code = $exitCode."
				exit $exitCode
			fi
			
		else
						
			"$CDAF_CORE/execute.sh" "$SOLUTION" "$BUILDNUMBER" "$BUILDENV" "build.tsk" "$ACTION" 2>&1
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "[$scriptName] Linear deployment activity ($CDAF_CORE/execute.sh $SOLUTION $BUILDNUMBER $projectName build.tsk) failed! Returned $exitCode"
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
