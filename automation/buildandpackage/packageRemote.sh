#!/usr/bin/env bash
scriptName=${0##*/}

# Arguments are not validated in sub-scripts, only at entry point
SOLUTION=$1
BUILDNUMBER=$2
REVISION=$3
WORK_DIR_DEFAULT=$4
SOLUTIONROOT=$5
AUTOMATIONROOT=$6

solutionCustomDir="./$SOLUTIONROOT/custom"
remoteCustomDir="./$SOLUTIONROOT/customRemote"
remoteCryptDir="./$SOLUTIONROOT/cryptRemote"
cryptDir="./$SOLUTIONROOT/crypt"
remoteArtifactListFile="./$SOLUTIONROOT/storeForRemote"

echo; echo "$scriptName : --- PACKAGE remotely executed scripts and artifacts ---"
echo "$scriptName :   WORK_DIR_DEFAULT            : $WORK_DIR_DEFAULT"

printf "$scriptName :   remote artifact list        : "
if [ -f  "$remoteArtifactListFile" ]; then
	echo "found ($remoteArtifactListFile)"
else
	echo "none ($remoteArtifactListFile)"
fi

printf "$scriptName :   custom scripts              : "
if [ -d  "$solutionCustomDir" ]; then
	echo "found ($solutionCustomDir)"
else
	echo "none ($solutionCustomDir)"
fi

printf "$scriptName :   remote custom scripts       : "
if [ -d  "$remoteCustomDir" ]; then
	echo "found ($remoteCustomDir)"
else
	echo "none ($remoteCustomDir)"
fi

printf "$scriptName :   remote encrypted files      : "
if [ -d  "$remoteCryptDir" ]; then
	echo "found ($remoteCryptDir)"
else
	echo "none ($remoteCryptDir)"
fi

printf "$scriptName :   common encrypted files      : "
if [ -d  "$cryptDir" ]; then
	echo "found ($cryptDir)"
else
	echo "none ($cryptDir)"
fi

echo; echo "$scriptName : Create working directory and seed with solution files"
mkdir -v $WORK_DIR_DEFAULT
mv -v manifest.txt $WORK_DIR_DEFAULT
cp -v $AUTOMATIONROOT/CDAF.linux $WORK_DIR_DEFAULT/CDAF.properties
echo
cp -avR $AUTOMATIONROOT/remote/* $WORK_DIR_DEFAULT

# Merge Remote tasks with general tasks, remote first
if [ -f  "./$SOLUTIONROOT/tasksRunRemote.tsk" ]; then
	echo
	printf "Tasks to execute on remote host : "	
	cp -av ./$SOLUTIONROOT/tasksRunRemote.tsk $WORK_DIR_DEFAULT
fi

# 1.7.8 Merge generic tasks into explicit tasks
if [ -f "$SOLUTIONROOT/tasksRun.tsk" ]; then
	echo "'$SOLUTIONROOT/tasksRun.tsk' -> '$WORK_DIR_DEFAULT/tasksRunRemote.tsk'"
	cat $SOLUTIONROOT/tasksRun.tsk >> $WORK_DIR_DEFAULT/tasksRunRemote.tsk
fi

if [ -d  "$remoteCryptDir" ]; then
	echo
	echo "$scriptName :   Remote encrypted files in $remoteCryptDir: "	
	cp -avR $remoteCryptDir/* $WORK_DIR_DEFAULT
fi

# CDAF 1.9.5 common encrypted files
if [ -d  "$cryptDir" ]; then
	echo
	echo "$scriptName :   Remote encrypted files in $cryptDir: "	
	cp -avR $cryptDir/* $WORK_DIR_DEFAULT
fi

# CDAF 1.7.3 Solution Custom scripts, included in Local and Remote
if [ -d  "$solutionCustomDir" ]; then
	echo
	echo "$scriptName :   Custom scripts in $solutionCustomDir           : "	
	cp -avR $solutionCustomDir/* $WORK_DIR_DEFAULT/
fi

if [ -d  "$remoteCustomDir" ]; then
	echo
	echo "$scriptName :   Remote custom scripts in $remoteCustomDir : "	
	cp -avR $remoteCustomDir/* $WORK_DIR_DEFAULT/
fi

# Process Specific remote artifacts
$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh $remoteArtifactListFile $WORK_DIR_DEFAULT

# Process generic artifacts, i.e. applies to both local and remote
if [ -f "${SOLUTIONROOT}/storeFor" ]; then
	$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh "${SOLUTIONROOT}/storeFor" $WORK_DIR_DEFAULT
fi

cd $WORK_DIR_DEFAULT
echo; echo "$scriptName : Create the package (tarball) file, excluding git or svn control files"; echo
tar -zcv --exclude='.git' --exclude='.svn' -f ../$SOLUTION-$BUILDNUMBER.tar.gz .

cd ..

exit 0
