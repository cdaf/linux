#!/usr/bin/env bash
set -e

# Arguments are not validated in sub-scripts, only at entry point
SOLUTION=$1
BUILDNUMBER=$2
REVISION=$3
WORK_DIR_DEFAULT=$4
SOLUTIONROOT=$5
AUTOMATIONROOT=$6

remoteCustomDir="./$SOLUTIONROOT/customRemote"
remoteCustomDir="./$SOLUTIONROOT/customRemote"
remoteCryptDir="./$SOLUTIONROOT/cryptRemote"
remoteArtifactListFile="./$SOLUTIONROOT/storeForRemote"
echo
echo "$0 : --- PACKAGE remotely executed scripts and artifacts ---"
echo
echo "$0 :   WORK_DIR_DEFAULT       : $WORK_DIR_DEFAULT"

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

# CDM-101 If Artefacts definition file is not found, do not perform any action, i.e. this solution is local tasks only
if [ ! -f  "$remoteArtifactListFile" ]; then
	echo
	echo "$0 : Artefacts definition file not found $remoteArtifactListFile, therefore no action, assuming local tasks only."
else
	echo
	echo "$0 : Create working directory and seed with solution files"
	mkdir -v $WORK_DIR_DEFAULT
	mv -v manifest.txt $WORK_DIR_DEFAULT
	cp -v $AUTOMATIONROOT/CDAF.linux $WORK_DIR_DEFAULT/CDAF.properties
	echo
	cp -avR ./$AUTOMATIONROOT/remote/* $WORK_DIR_DEFAULT
	
	if [ -f  "./$SOLUTIONROOT/tasksRunRemote.tsk" ]; then
		echo
		printf "Tasks to execute on remote host : "	
		cp -av ./$SOLUTIONROOT/tasksRunRemote.tsk $WORK_DIR_DEFAULT
	fi
	
	if [ -d  "$remoteCryptDir" ]; then
		echo
		echo "$0 :   Remote encrypted files in $remoteCryptDir: "	
		cp -avR $remoteCryptDir/* $WORK_DIR_DEFAULT
	fi
	
	if [ -d  "$remoteCustomDir" ]; then
		echo
		echo "$0 :   Remote custom scripts in $remoteCustomDir : "	
		cp -avR $remoteCustomDir/* $WORK_DIR_DEFAULT/
	fi
	
	./$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh $remoteArtifactListFile $WORK_DIR_DEFAULT
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$0 : ./$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh $remoteArtifactListFile $WORK_DIR_DEFAULT failed! Exit code = $exitCode."
		exit $exitCode
	fi
	
	cd $WORK_DIR_DEFAULT
	echo	
	echo "$0 : Create the package (tarball) file, excluding git or svn control files"
	echo
	tar -zcv --exclude='.git' --exclude='.svn' -f ../$SOLUTION-$BUILDNUMBER.tar.gz .
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$0 : tar -zcv --exclude=\'.git\' --exclude=\'.svn\' -f ../$SOLUTION-$BUILDNUMBER.tar.gz . failed! Exit = $exitCode"
		exit $exitCode
	fi
	cd ..
	
fi
