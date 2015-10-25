#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Solution Name not supplied. HALT!"
	exit 1
else
	SOLUTION=$1
fi

if [ -z "$2" ]; then
	echo "$0 : Build Identifier not supplied. HALT!"
	exit 2
else
	BUILDNUMBER=$2
fi

if [ -z "$3" ]; then
	echo "$0 : Source Control System Revision ID not supplied. HALT!"
	exit 3
else
	REVISION=$3
fi

if [ -z "$4" ]; then
	echo "$0 : Local Working Directory not supplied. HALT!"
	exit 4
else
	LOCAL_WORK_DIR=$4
fi

if [ -z "$4" ]; then
	echo "$0 : Local Working Directory not supplied. HALT!"
	exit 4
else
	REMOTE_WORK_DIR=$5
fi

# Action is optional
ACTION="$6"

echo
echo "$0 : +-----------------+"
echo "$0 : | Package Process |"
echo "$0 : +-----------------+"
echo "$0 :   SOLUTION                 : $SOLUTION"
echo "$0 :   BUILDNUMBER              : $BUILDNUMBER"
echo "$0 :   REVISION                 : $REVISION"
echo "$0 :   LOCAL_WORK_DIR           : $LOCAL_WORK_DIR"
echo "$0 :   REMOTE_WORK_DIR          : $REMOTE_WORK_DIR"

# Look for automation root definition, if not found, default
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.linux" ]; then
		AUTOMATIONROOT="$directoryName"
		echo "$0 :   AUTOMATIONROOT           : $AUTOMATIONROOT (CDAF.linux found)"
	fi
done
if [ -z "$AUTOMATIONROOT" ]; then
	AUTOMATIONROOT="automation"
	echo "$0 :   AUTOMATIONROOT           : $AUTOMATIONROOT (CDAF.linux not found)"
fi

# Process all entry values
automationHelper="./$AUTOMATIONROOT/remote"
SOLUTIONROOT="$AUTOMATIONROOT/solution"
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
		SOLUTIONROOT="$directoryName"
	fi
done
echo "$0 :   SOLUTIONROOT             : $SOLUTIONROOT"

printf "$0 :   Pre-package Tasks        : "
prepackageTasks="$SOLUTIONROOT/package.tsk"
if [ -f $prepackageTasks ]; then
	echo "found ($prepackageTasks)"
else
	echo "none ($prepackageTasks)"
fi

printf "$0 :   Post-package Tasks       : "
postpackageTasks="$SOLUTIONROOT/wrap.tsk"
if [ -f $postpackageTasks ]; then
	echo "found ($postpackageTasks)"
else
	echo "none ($postpackageTasks)"
fi

remotePropertiesDir="$SOLUTIONROOT/propertiesForRemoteTasks"
printf "$0 :   Remote Target Directory  : "
if [ -d  "$remotePropertiesDir" ]; then
	echo "found ($remotePropertiesDir)"
else
	echo "none ($remotePropertiesDir)"
fi

echo
echo "$0 : Clean root workspace ($(pwd))"
echo
rm -fv *.log *.zip *.txt
rm -rf $LOCAL_WORK_DIR $REMOTE_WORK_DIR
echo
echo "$0 : Remove working directories"
echo
if [ -d  "$LOCAL_WORK_DIR" ]; then
	echo "remove $LOCAL_WORK_DIR"
	rm -rf $LOCAL_WORK_DIR
fi

if [ -d  "$REMOTE_WORK_DIR" ]; then
	echo "remove $REMOTE_WORK_DIR"
	rm -rf $REMOTE_WORK_DIR
fi

if [ "$ACTION" == "clean" ]; then
	echo
	echo "$0 : Solution Workspace Clean Only"
	
else
	
	# Process optional pre-packaging tasks (Task driver support added in release 0.7.2)
	if [ -f $prepackageTasks ]; then
		echo
		echo "Process Pre-Package Tasks ..."
		echo
		echo "AUTOMATIONROOT=$AUTOMATIONROOT" > ./package.properties
		echo "SOLUTIONROOT=$SOLUTIONROOT" >> ./package.properties
		$automationHelper/execute.sh "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$prepackageTasks" "$ACTION" 2>&1 | tee -a prePackage.log
		# the pipe above will consume the exit status, so use array of status of each command in your last foreground pipeline of commands
		exitCode=${PIPESTATUS[0]} 
		if [ "$exitCode" != "0" ]; then
			echo "$0 : Linear deployment activity ($automationHelper/execute.sh $SOLUTION $BUILDNUMBER package $SOLUTIONROOT/package.tsk) failed! Returned $exitCode"
			exit $exitCode
		fi
	fi

	# Process solution properties if defined
	if [ -f "$SOLUTIONROOT/CDAF.solution" ]; then
		echo
		echo "CDAF.solution file found in directory \"$SOLUTIONROOT\", load solution properties"
		propertiesList=$($automationHelper/transform.sh "$SOLUTIONROOT/CDAF.solution")
		echo "$propertiesList"
	fi

	# Load Manifest, these properties are used by remote deployment
	echo "# Manifest for revision $REVISION" > manifest.txt
	echo "SOLUTION=$SOLUTION" >> manifest.txt
	echo "BUILDNUMBER=$BUILDNUMBER" >> manifest.txt
	echo
	echo "$0 : Always create local working artefacts, even if all tasks are remote"
	echo
	./$AUTOMATIONROOT/buildandpackage/packageLocal.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$LOCAL_WORK_DIR" "$SOLUTIONROOT" "$AUTOMATIONROOT"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$0 : ./packageLocal.sh failed! Exit code = $exitCode."
		exit $exitCode
	fi

	# Only create the remote package if there is a remote target folder, if folder exists
	# create the remote package (even if there are no target files within it)
	if [ -d  "$remotePropertiesDir" ]; then
		./$AUTOMATIONROOT/buildandpackage/packageRemote.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$REMOTE_WORK_DIR" "$SOLUTIONROOT" "$AUTOMATIONROOT"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo "$0 : ./packageRemote.sh failed! Exit code = $exitCode."
			exit $exitCode
		fi
	fi

	# Process optional post-packaging tasks (Task driver support added in release 0.8.2)
	if [ -f $postpackageTasks ]; then
		echo
		echo "Process Post-Package Tasks ..."
		echo
		$automationHelper/execute.sh "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$postpackageTasks" "$ACTION" 2>&1 | tee -a postPackage.log
		# the pipe above will consume the exit status, so use array of status of each command in your last foreground pipeline of commands
		exitCode=${PIPESTATUS[0]} 
		if [ "$exitCode" != "0" ]; then
			echo "$0 : Linear deployment activity ($automationHelper/execute.sh $SOLUTION $BUILDNUMBER package $SOLUTIONROOT/package.tsk) failed! Returned $exitCode"
			exit $exitCode
		fi
	fi

fi
echo
echo "$0 : --- Solution Packaging Complete ---"
