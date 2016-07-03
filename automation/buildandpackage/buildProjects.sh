#!/usr/bin/env bash

echo
echo "$0 : +----------------------------+"
echo "$0 : | Process BUILD all projects |"
echo "$0 : +----------------------------+"
echo
if [ -z "$1" ]; then
	echo "$0 : Solution not passed!"
	exit 1
else
	SOLUTION="$1"
	echo "$0 :   SOLUTION       : $SOLUTION"
fi

if [ -z "$2" ]; then
	echo "$0 : Build Number not passed!"
	exit 2
else
	BUILDNUMBER="$2"
	echo "$0 :   BUILDNUMBER    : $BUILDNUMBER"
fi

if [ -z "$3" ]; then
	echo "$0 : Revision not passed!"
	exit 3
else
	REVISION="$3"
	echo "$0 :   REVISION       : $REVISION"
fi

if [ -z "$4" ]; then
	echo "$0 : Environment not passed!"
	exit 4
else
	BUILDENV="$4"
	echo "$0 :   BUILDENV       : $BUILDENV"
fi

if [ ! -z "$5" ]; then
	ACTION="$5"
	echo "$0 :   ACTION         : $ACTION"
fi

# Look for automation root definition, if not found, default
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.linux" ] ; then
		AUTOMATIONROOT="$directoryName"
		echo "$0 :   AUTOMATIONROOT : $AUTOMATIONROOT (CDAF.linux found)"
	fi
done
if [ -z "$AUTOMATIONROOT" ]; then
	AUTOMATIONROOT="automation"
	echo "$0 :   AUTOMATIONROOT : $AUTOMATIONROOT (CDAF.linux not found)"
fi

echo
echo "$0 : $automessage"
AUTOMATIONHELPER="./$AUTOMATIONROOT/remote"

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
SOLUTIONROOT="$AUTOMATIONROOT/solution"
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ]; then
		echo "$0 : CDAF.solution file found in directory $directoryName, load solution properties"
		SOLUTIONROOT="$directoryName"
		propertiesList=$($AUTOMATIONHELPER/transform.sh "$directoryName/CDAF.solution")
		echo
		echo "$propertiesList"
		eval $propertiesList
	fi
done

customProjectList="$SOLUTIONROOT/buildProjects"

if [ ! -f "$customProjectList" ]; then

	if [ -f "dirListFile" ]; then
		rm dirListFile
	fi

	# If a custom list is not supplied, create initial list from directories in workspace
    for i in $(ls -d */); do
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
	echo "$0 :   Projects to process :"
	echo
	cat projectListFile

	while read PROJECT
	do
		
		echo
		echo "$0 : --- BUILD $PROJECT ---"
		echo
		cd $PROJECT
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo "$0 : cd $PROJECT failed! Exit code = $exitCode."
			exit $exitCode
		fi

		# Additional properties that are not passed as arguments		
		echo "REVISION=$REVISION" > ../build.properties
		echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ../build.properties
		echo "SOLUTIONROOT=$SOLUTIONROOT" >> ../build.properties
		if [ -f "build.sh" ]; then
		
			./build.sh "$SOLUTION" "$BUILDNUMBER" "$PROJECT" "$ACTION"
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "$0 : $PROJECT Build Failed, exit code = $exitCode."
				exit $exitCode
			fi
			
		else
			
			.$AUTOMATIONHELPER/execute.sh "$SOLUTION" "$BUILDNUMBER" "$PROJECT" "build.tsk" "$ACTION" 2>&1
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "$0 : Linear deployment activity (.$AUTOMATIONHELPER/execute.sh $SOLUTION $BUILDNUMBER $PROJECT build.tsk) failed! Returned $exitCode"
				exit $exitCode
			fi
		fi
		
		cd ..
	
		lastProject=$(echo $PROJECT)
	
	done < projectListFile
	
	if [ -z $lastProject ]; then
		echo
		echo "$0 : No projects found containing build.sh, no build action attempted."
		echo
	fi
	
	# Cleanup temp file
	rm projectListFile

else

	echo
	echo "$0 : No projects found, no build action attempted."
	echo

fi
