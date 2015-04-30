#!/usr/bin/env bash
set -e

# Build All Projects

if [ -z "$1" ]; then
	echo "$0 : Solution not passed!"
	exit 1
else
	SOLUTION="$1"
fi

if [ -z "$2" ]; then
	echo "$0 : Build Number not passed!"
	exit 2
else
	BUILDNUMBER="$2"
fi

if [ -z "$3" ]; then
	echo "$0 : Revision not passed!"
	exit 3
else
	REVISION="$3"
fi

if [ -z "$4" ]; then
	echo "$0 : Environment not passed!"
	exit 4
else
	BUILDENV="$4"
fi

if [ ! -z "$5" ]; then
	ACTION="$5"
fi

echo
echo "$0 : +----------------------------+"
echo "$0 : | Process BUILD all projects |"
echo "$0 : +----------------------------+"
echo
echo "$0 :   SOLUTION     : $SOLUTION"
echo "$0 :   BUILDNUMBER  : $BUILDNUMBER"
echo "$0 :   REVISION     : $REVISION"
echo "$0 :   BUILDENV     : $BUILDENV"
echo "$0 :   ACTION       : $ACTION"
echo "$0 :   pwd          : $(pwd)"
echo

AUTOMATIONROOT="automation"
AUTOMATIONHELPER="./$AUTOMATIONROOT/remote"

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
SOLUTIONROOT="$AUTOMATIONROOT/solution"
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ]; then
		echo "CDAF.solution file found in directory $directoryName, load solution properties"
		SOLUTIONROOT="$directoryName"
		propertiesList=$($AUTOMATIONHELPER/transform.sh "$directoryName/CDAF.solution")
		echo "$propertiesList"
		eval $propertiesList
		echo
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
		
		if [ -f "build.sh" ]; then
		
			./build.sh "$PROJECT" "$BUILDNUMBER" "$REVISION" "$ACTION"
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "$0 : $PROJECT Build Failed, exit code = $exitCode."
				exit $exitCode
			fi
			
		else
			echo "PROJECT=$PROJECT" > ../build.properties
			echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ../build.properties
			echo "SOLUTIONROOT=$SOLUTIONROOT" >> ../build.properties
			.$AUTOMATIONHELPER/execute.sh "$PROJECT" "$BUILDNUMBER" "$BUILDENV" "build.tsk" "$ACTION" 2>&1 | tee -a postDeploy.log
			# the pipe above will consume the exit status, so use array of status of each command in your last foreground pipeline of commands
			exitCode=${PIPESTATUS[0]} 
			if [ "$exitCode" != "0" ]; then
				echo "$0 : Linear deployment activity (.$AUTOMATIONHELPER/execute.sh $PROJECT $BUILDNUMBER $BUILDENV build.tsk) failed! Returned $exitCode"
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
