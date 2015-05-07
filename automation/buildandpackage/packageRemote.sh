#!/usr/bin/env bash
set -e

# Arguments are not validated in sub-scripts, only at entry point
SOLUTION=$1
BUILDNUMBER=$2
REVISION=$3
WORK_DIR_DEFAULT=$4
SCRIPT_DIR=$5
SOLUTIONROOT=$6
AUTOMATIONROOT=$7

remoteCustomDir="../$SOLUTIONROOT/customRemote"
remoteCryptDir="../$SOLUTIONROOT/cryptRemote"
remoteArtifactListFile="./$SOLUTIONROOT/storeForRemote"
echo
echo "$0 : --- PACKAGE remotely executed scripts and artifacts ---"
echo
echo "$0 :   WORK_DIR_DEFAULT       : $WORK_DIR_DEFAULT"
echo "$0 :   SCRIPT_DIR             : $SCRIPT_DIR"

printf "$0 :   remote artifact list   : "
if [ -f  "$remoteArtifactListFile" ]; then
	echo "found ($remoteArtifactListFile)"
else
	echo "none ($remoteArtifactListFile)"
fi

printf "$0 :   remote custom scripts  : "
if [ -d  "$remoteCustomDir" ]; then
	echo "found ($remoteCustomDir)"
else
	echo "none ($remoteCustomDir)"
fi

printf "$0 :   remote encrypted files : "
if [ -d  "$remoteCryptDir" ]; then
	echo "found ($remoteCryptDir)"
else
	echo "none ($remoteCryptDir)"
fi

echo
echo "$0 : Copy scripts required on target(s)"
echo
mkdir -v $WORK_DIR_DEFAULT
mv -v manifest.txt $WORK_DIR_DEFAULT
cd $WORK_DIR_DEFAULT

mkdir -v $SCRIPT_DIR
cp -avR ../$AUTOMATIONROOT/remote/* $SCRIPT_DIR

if [ -f  "../$SOLUTIONROOT/tasksRunRemote.tsk" ]; then
	cp -av ../$SOLUTIONROOT/tasksRunRemote.tsk $SCRIPT_DIR
fi

if [ -d  "$remoteCryptDir" ]; then
	printf "$0 :   Remote encrypted files : "	
	mkdir -v $SCRIPT_DIR/${remoteCryptDir##*/}
	cp -avR $remoteCryptDir/* $SCRIPT_DIR/${remoteCryptDir##*/}
fi

if [ -d  "$remoteCustomDir" ]; then
	printf "$0 :   Remote custom scripts : "	
	mkdir -v $SCRIPT_DIR/${remoteCustomDir##*/}
	cp -avR $remoteCustomDir/* $SCRIPT_DIR/${remoteCustomDir##*/}
fi

# Return to workspace root
cd ..

# Process Build Artefacts if a definition file is found
if [ ! -f  "$remoteArtifactListFile" ]; then
	echo "$0 : Artefacts definition file not found $remoteArtifactListFile, assuming this has been intentionally removed, continuing without error."
	echo
	ls -l
else
	./$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh $remoteArtifactListFile $WORK_DIR_DEFAULT
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$0 : ./$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh $remoteArtifactListFile $WORK_DIR_DEFAULT failed! Exit code = $exitCode."
		exit $exitCode
	fi
fi	

# Enter the default directory to create zip package file 
cd $WORK_DIR_DEFAULT

echo	
echo "$0 : Create the package (zip) file"
echo
zip -r ../$SOLUTION-$BUILDNUMBER.zip . -x *.git *.svn*
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo "$0 : zip -r ../$SOLUTION-$BUILDNUMBER.zip . -x *.git *.svn* failed! Exit = $exitCode"
	exit $exitCode
fi
# Return to workspace root
cd ..
