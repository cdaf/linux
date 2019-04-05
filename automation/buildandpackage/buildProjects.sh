#!/usr/bin/env bash

scriptName=${0##*/}

echo; echo "$scriptName : +----------------------------+"
echo "$scriptName : | Process BUILD all projects |"
echo "$scriptName : +----------------------------+"; echo
SOLUTION="$1"
if [ -z "$SOLUTION" ]; then
	echo "$scriptName : Solution not passed!"
	exit 1
else
	echo "$scriptName :   SOLUTION          : $SOLUTION"
fi

BUILDNUMBER="$2"
if [ -z "$BUILDNUMBER" ]; then
	echo "$scriptName : Build Number not passed!"
	exit 2
else
	echo "$scriptName :   BUILDNUMBER       : $BUILDNUMBER"
fi

REVISION="$3"
if [ -z "$REVISION" ]; then
	REVISION="Revision"
	echo "$scriptName :   REVISION          : $REVISION (default)"
else
	echo "$scriptName :   REVISION          : $REVISION"
fi

ACTION="$4"
if [ -z "$ACTION" ]; then
	echo "$scriptName :   ACTION            : $ACTION"
	BUILDENV='BUILDER'
	echo "$scriptName :   BUILDENV          : $BUILDENV (default because ACTION not supplied)"
else
	# case insensitive by forcing to uppercase
	testForClean=$(echo "$ACTION" | tr '[a-z]' '[A-Z]')
	if [ "$testForClean" == "CLEAN" ]; then
		echo "$scriptName :   ACTION            : $ACTION (Build Environment will be set to default)"
		BUILDENV='BUILDER'
		echo "$scriptName :   BUILDENV          : $BUILDENV (default)"
	else
		BUILDENV="$ACTION"
		echo "$scriptName :   ACTION            : $ACTION"
		echo "$scriptName :   BUILDENV          : $BUILDENV (derived from action)"
	fi
fi

# Look for automation root definition, if not found, default
for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.linux" ] ; then
		AUTOMATIONROOT="$directoryName"
		echo "$scriptName :   AUTOMATIONROOT    : $AUTOMATIONROOT (CDAF.linux found)"
	fi
done
if [ -z "$AUTOMATIONROOT" ]; then
	AUTOMATIONROOT="automation"
	echo "$scriptName :   AUTOMATIONROOT    : $AUTOMATIONROOT (CDAF.linux not found)"
fi

AUTOMATIONHELPER="$AUTOMATIONROOT/remote"

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
SOLUTIONROOT="$AUTOMATIONROOT/solution"
for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ]; then
		SOLUTIONROOT="$directoryName"
	fi
done

echo; echo "$scriptName : CDAF.solution file found in directory $SOLUTIONROOT, load solution properties"
if [ -f "$SOLUTIONROOT/CDAF.solution" ]; then
	propertiesList=$($AUTOMATIONHELPER/transform.sh "$SOLUTIONROOT/CDAF.solution")
	echo; echo "$propertiesList"
	eval $propertiesList
else
	echo; echo "$scriptName : CDAF.solution file not found!"; exit 8823
fi

echo; echo "$scriptName : Remove working directories"; echo # perform explicit removal as rm -rfv is too verbose
for packageDir in $(echo "./propertiesForRemoteTasks ./propertiesForLocalTasks"); do
	if [ -d  "${packageDir}" ]; then
		echo "  removed ${packageDir}"
		rm -rf ${packageDir}
	fi
done

if [ -f "build.sh" ]; then
	echo; echo "$scriptName : build.sh found in solution root, executing in $(pwd)"; echo
	# Additional properties that are not passed as arguments, but loaded by execute automatically
	echo "PROJECT=$PROJECT" > ./solution.properties
	echo "REVISION=$REVISION" >> ./solution.properties
	echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ./solution.properties
	echo "SOLUTIONROOT=$SOLUTIONROOT" >> ./solution.properties
	./build.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$BUILDENV" "$ACTION"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$scriptName : $PROJECT Build Failed, exit code = $exitCode."
		exit $exitCode
	fi
fi
	
if [ -f "build.tsk" ]; then

	echo; echo "$scriptName : build.tsk found in solution root, executing in $(pwd)"; echo
	# Additional properties that are not passed as arguments, explicit load is required
	echo "PROJECT=$PROJECT" > ./solution.properties
	echo "REVISION=$REVISION" >> ./solution.properties
	echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ./solution.properties
	echo "SOLUTIONROOT=$SOLUTIONROOT" >> ./solution.properties
	$AUTOMATIONHELPER/execute.sh "$SOLUTION" "$BUILDNUMBER" "$BUILDENV" "build.tsk" "$ACTION" 2>&1
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$scriptName : Linear deployment activity ($AUTOMATIONHELPER/execute.sh $SOLUTION $BUILDNUMBER $PROJECT build.tsk) failed! Returned $exitCode"
		exit $exitCode
	fi
fi

customProjectList="$SOLUTIONROOT/buildProjects"

if [ ! -f "$customProjectList" ]; then

	if [ -f "dirListFile" ]; then
		rm dirListFile
	fi

	# If a custom list is not supplied, create initial list from directories in workspace
    for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
		echo ${i%%/} >> dirListFile
	done
else
	cp $customProjectList dirListFile
fi

# Create a list of projects based on directories containing build script entry point
if [ -f "projectListFile" ]; then
	rm projectListFile
fi
while read DIR; do

	if [ -f "$DIR/build.sh" ] || [ -f "$DIR/build.tsk" ]; then
		echo $DIR >> projectListFile
	fi

done < dirListFile

# Cleanup temp file
if [ -f "dirListFile" ]; then
	rm dirListFile
fi

if [ -f "projectListFile" ]; then
	echo "$scriptName :   Projects to process :"; echo
	cat projectListFile

	while read PROJECT
	do
		
		echo; echo "$scriptName : --- BUILD $PROJECT ---"; echo
		cd $PROJECT
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo "$scriptName : cd $PROJECT failed! Exit code = $exitCode."
			exit $exitCode
		fi

		# Additional properties that are not passed as arguments, but loaded by execute automatically, to use in build.sh, explicit load is required		
		echo "PROJECT=$PROJECT" > ../build.properties
		echo "REVISION=$REVISION" >> ../build.properties
		echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ../build.properties
		echo "SOLUTIONROOT=$SOLUTIONROOT" >> ../build.properties

		if [ -f "build.sh" ]; then
		
			./build.sh "$SOLUTION" "$BUILDNUMBER" "$BUILDENV" "$ACTION"
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "$scriptName : $PROJECT Build Failed, exit code = $exitCode."
				exit $exitCode
			fi
			
		else
						
			../$AUTOMATIONHELPER/execute.sh "$SOLUTION" "$BUILDNUMBER" "$BUILDENV" "build.tsk" "$ACTION" 2>&1
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "$scriptName : Linear deployment activity ($AUTOMATIONHELPER/execute.sh $SOLUTION $BUILDNUMBER $PROJECT build.tsk) failed! Returned $exitCode"
				exit $exitCode
			fi
		fi
		
		cd ..
	
		lastProject=$(echo $PROJECT)
	
	done < projectListFile
	
	if [ -z $lastProject ]; then
		echo
		echo "$scriptName : No projects found containing build.sh, no build action attempted."
		echo
	fi
	
	# Cleanup temp file
	rm projectListFile

else

	echo; echo "$scriptName : No projects found, no build action attempted."; echo

fi
