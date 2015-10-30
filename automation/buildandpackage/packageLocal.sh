#!/usr/bin/env bash
set -e

# Arguments are not validated in sub-scripts, only at entry point
SOLUTION=$1
BUILDNUMBER=$2
REVISION=$3
WORK_DIR_DEFAULT=$4
SOLUTIONROOT=$5
AUTOMATIONROOT=$6

localArtifactListFile="$SOLUTIONROOT/storeForLocal"
localPropertiesDir="$SOLUTIONROOT/propertiesForLocalTasks"
localCustomDir="$SOLUTIONROOT/customLocal"
localCryptDir="$SOLUTIONROOT/cryptLocal"
remotePropertiesDir="$SOLUTIONROOT/propertiesForRemoteTasks"

echo "$0 : --- PACKAGE locally executed scripts and artefacts ---"
echo
echo "$0 :   WORK_DIR_DEFAULT            : $WORK_DIR_DEFAULT"

printf "$0 :   local artifact list         : "
if [ -f  "$localArtifactListFile" ]; then
	echo "found ($localArtifactListFile)"
else
	echo "none ($localArtifactListFile)"
fi

printf "$0 :   Properties for local tasks  : "
if [ -d  "$localPropertiesDir" ]; then
	echo "found ($localPropertiesDir)"
else
	echo "none ($localPropertiesDir)"
fi

printf "$0 :   local encrypted files       : "
if [ -d  "$localCryptDir" ]; then
	echo "found ($localCryptDir)"
else
	echo "none ($localCryptDir)"
fi

printf "$0 :   local custom scripts        : "
if [ -d  "$localCustomDir" ]; then
	echo "found ($localCustomDir)"
else
	echo "none ($localCustomDir)"
fi

printf "$0 :   Properties for remote tasks : "
if [ -d  "$remotePropertiesDir" ]; then
	echo "found ($remotePropertiesDir)"
else
	echo "none ($remotePropertiesDir)"
fi

echo
echo "$0 : Copy scripts and properties files required locally"
echo
mkdir -v $WORK_DIR_DEFAULT
cp -av manifest.txt $WORK_DIR_DEFAULT
cp -avR $AUTOMATIONROOT/local/* $WORK_DIR_DEFAULT

if [ -d "$localPropertiesDir" ]; then
	filesInDir=$(ls $localPropertiesDir)
	if [ -n "$filesInDir" ]; then
		echo
		echo "$0 :   Properties for local tasks ($localPropertiesDir) : "	
		echo
		# Copy files to driver directory and to the root directory
		mkdir -v $WORK_DIR_DEFAULT/${localPropertiesDir##*/}
		cp -avR $localPropertiesDir/* $WORK_DIR_DEFAULT/${localPropertiesDir##*/}
		cp -avR $localPropertiesDir/* $WORK_DIR_DEFAULT/

		# If there are properties files but no default task, log a warning (not an error because may have override tasks defined in properties files themselves)
		if [ -f "$SOLUTIONROOT/tasksRunLocal.tsk" ]; then
			cp -av $SOLUTIONROOT/tasksRunLocal.tsk $WORK_DIR_DEFAULT
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "$0 : cp -av $SOLUTIONROOT/tasksRunLocal.tsk $WORK_DIR_DEFAULT failed! Exit code = $exitCode."
				exit $exitCode
			fi
		else
			echo
			echo "$0 : Warning : Default Task ($SOLUTIONROOT/tasksRunLocal.tsk) not found, override task must be defined for each properties file."
		fi
				
	else
		echo
		echo "$0 :   Properties directory ($localPropertiesDir) for local tasks exists but contains no files, no action taken."
		echo
	fi
fi

if [ -d "$localCryptDir" ]; then
	printf "$0 :   Local encrypted files : "	
	mkdir -v $WORK_DIR_DEFAULT/${localCryptDir##*/}
	cp -avR $localCryptDir/* $WORK_DIR_DEFAULT/${localCryptDir##*/}
fi

if [ -d "$localCustomDir" ]; then
	printf "$0 :   Local custom scripts : "	
	mkdir -v $WORK_DIR_DEFAULT/${localCustomDir##*/}
	cp -avR $localCustomDir/* $WORK_DIR_DEFAULT/${localCustomDir##*/}
fi

# Do not attempt to create the directory and copy files unless the source directory exists AND contains files
if [ -d "$remotePropertiesDir" ]; then
	filesInDir=$(ls $remotePropertiesDir)
	if [ -n "$filesInDir" ]; then
		echo
		echo "$0 :   Properties for remote tasks ($remotePropertiesDir) : "
		echo
		mkdir -v $WORK_DIR_DEFAULT/${remotePropertiesDir##*/}
		cp -avR $remotePropertiesDir/* $WORK_DIR_DEFAULT/${remotePropertiesDir##*/}
	else
		echo
		echo "$0 :   Properties directory ($remotePropertiesDir) for remote tasks exists but contains no files, no action taken."
		echo
	fi
fi

# Copy all helper scripts from remote to local
cp -av $AUTOMATIONROOT/remote/*.sh $WORK_DIR_DEFAULT
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo "$0 : cp -av $AUTOMATIONROOT/remote/*.sh $WORK_DIR_DEFAULT failed! Exit code = $exitCode."
	exit $exitCode
fi

# Process Build Artefacts
./$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh $localArtifactListFile $WORK_DIR_DEFAULT
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo "$0 : ./$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh $localArtifactListFile $WORK_DIR_DEFAULT failed! Exit code = $exitCode."
	exit $exitCode
fi
