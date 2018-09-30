#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# Arguments are not validated in sub-scripts, only at entry point
SOLUTION=$1
BUILDNUMBER=$2
REVISION=$3
WORK_DIR_DEFAULT=$4
SOLUTIONROOT=$5
AUTOMATIONROOT=$6

localArtifactListFile="$SOLUTIONROOT/storeForLocal"
localPropertiesDir="$SOLUTIONROOT/propertiesForLocalTasks"
localGenPropDir="./propertiesForLocalTasks"
solutionCustomDir="$SOLUTIONROOT/custom"
localCustomDir="$SOLUTIONROOT/customLocal"
localCryptDir="$SOLUTIONROOT/cryptLocal"
remotePropertiesDir="$SOLUTIONROOT/propertiesForRemoteTasks"
remoteGenPropDir="./propertiesForRemoteTasks"

echo "$scriptName : --- PACKAGE locally executed scripts and artefacts ---"; echo
echo "$scriptName :   WORK_DIR_DEFAULT            : $WORK_DIR_DEFAULT"

printf "$scriptName :   local artifact list         : "
if [ -f  "$localArtifactListFile" ]; then
	echo "found ($localArtifactListFile)"
else
	echo "none ($localArtifactListFile)"
fi

printf "$scriptName :   Properties for local tasks  : "
if [ -d  "$localPropertiesDir" ]; then
	echo "found ($localPropertiesDir)"
else
	echo "none ($localPropertiesDir)"
fi

printf "$scriptName :   Generated local properties  : "
if [ -d  "$localGenPropDir" ]; then
	echo "found ($localGenPropDir)"
else
	echo "none ($localGenPropDir)"
fi

printf "$scriptName :   local encrypted files       : "
if [ -d  "$localCryptDir" ]; then
	echo "found ($localCryptDir)"
else
	echo "none ($localCryptDir)"
fi

printf "$scriptName :   custom scripts              : "
if [ -d  "$solutionCustomDir" ]; then
	echo "found ($solutionCustomDir)"
else
	echo "none ($solutionCustomDir)"
fi

printf "$scriptName :   local custom scripts        : "
if [ -d  "$localCustomDir" ]; then
	echo "found ($localCustomDir)"
else
	echo "none ($localCustomDir)"
fi

printf "$scriptName :   Properties for remote tasks : "
if [ -d  "$remotePropertiesDir" ]; then
	echo "found ($remotePropertiesDir)"
else
	echo "none ($remotePropertiesDir)"
fi

printf "$scriptName :   Generated remote properties : "
if [ -d  "$remoteGenPropDir" ]; then
	echo "found ($remoteGenPropDir)"
else
	echo "none ($remoteGenPropDir)"
fi

echo; echo "$scriptName : Create working directory and seed with solution files"; echo
mkdir -v $WORK_DIR_DEFAULT
cp -av manifest.txt $WORK_DIR_DEFAULT
cp -v $AUTOMATIONROOT/CDAF.linux $WORK_DIR_DEFAULT/CDAF.properties

echo; echo "$scriptName : Copy required local scripts"; echo
cp -avR $AUTOMATIONROOT/local/* $WORK_DIR_DEFAULT

# Only retain either the override or default delivery process
if [ -f "$SOLUTIONROOT/delivery.sh" ]; then
	cp -avR $SOLUTIONROOT/delivery.sh $WORK_DIR_DEFAULT
else
	cp -avR $AUTOMATIONROOT/processor/delivery.sh $WORK_DIR_DEFAULT
fi

if [ -d "$localPropertiesDir" ]; then
	filesInDir=$(ls $localPropertiesDir)
	if [ -n "$filesInDir" ]; then

		echo; echo "$scriptName :   Properties for local tasks ($localPropertiesDir) : "; echo
		# Copy files to driver directory and to the root directory
		mkdir -v $WORK_DIR_DEFAULT/${localPropertiesDir##*/}
		cp -avR $localPropertiesDir/* $WORK_DIR_DEFAULT/${localPropertiesDir##*/}
		cp -avR $localPropertiesDir/* $WORK_DIR_DEFAULT/

		# Include remote tasks should they be required for re-use as local tasks
		if [ -f "$SOLUTIONROOT/tasksRunRemote.tsk" ]; then
			cp -av $SOLUTIONROOT/tasksRunRemote.tsk $WORK_DIR_DEFAULT
		fi				
	else
		echo; echo "$scriptName :   Properties directory ($localPropertiesDir) for local tasks exists but contains no files, no action taken."; echo
	fi
fi

# Merge files into directory, i.e. don't replace any properties provided above
if [ -d "$localGenPropDir" ]; then
	echo; echo "$scriptName : Processing generated properties directory (${localGenPropDir}):"; echo
	if [ ! -d $WORK_DIR_DEFAULT/${localPropertiesDir##*/} ]; then
		mkdir -v $WORK_DIR_DEFAULT/${localPropertiesDir##*/}
	fi
	for generatedPropertyPath in $(find ${localGenPropDir}/ -type f); do
		generatedPropertyFile=$(basename ${generatedPropertyPath})
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${localPropertiesDir##*/}/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> $WORK_DIR_DEFAULT/${localPropertiesDir##*/}/${generatedPropertyFile}
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> $WORK_DIR_DEFAULT/${generatedPropertyFile}
	done
fi

# Merge Local tasks with general tasks, local first
if [ -f "$SOLUTIONROOT/tasksRunLocal.tsk" ]; then
	cp -av $SOLUTIONROOT/tasksRunLocal.tsk $WORK_DIR_DEFAULT
fi

# 1.7.8 Merge generic tasks into explicit tasks
if [ -f "$SOLUTIONROOT/tasksRun.tsk" ]; then
	echo "'$SOLUTIONROOT/tasksRun.tsk' -> '$WORK_DIR_DEFAULT/tasksRunLocal.tsk'"
	cat $SOLUTIONROOT/tasksRun.tsk >> $WORK_DIR_DEFAULT/tasksRunLocal.tsk
fi

if [ -d "$localCryptDir" ]; then
	printf "$scriptName :   Local encrypted files : "	
	mkdir -v $WORK_DIR_DEFAULT/${localCryptDir##*/}
	cp -avR $localCryptDir/* $WORK_DIR_DEFAULT/${localCryptDir##*/}
fi

# CDAF 1.7.3 Solution Custom scripts, included in Local and Remote
if [ -d "$solutionCustomDir" ]; then
	printf "$scriptName :   Custom scripts        : "	
	cp -avR $solutionCustomDir/* $WORK_DIR_DEFAULT/
fi

# Copy custom scripts to root
if [ -d "$localCustomDir" ]; then
	printf "$scriptName :   Local custom scripts  : "	
	cp -avR $localCustomDir/* $WORK_DIR_DEFAULT/
fi

# Do not attempt to create the directory and copy files unless the source directory exists AND contains files
if [ -d "$remotePropertiesDir" ]; then
	filesInDir=$(ls $remotePropertiesDir)
	if [ -n "$filesInDir" ]; then
		echo; echo "$scriptName :   Properties for remote tasks ($remotePropertiesDir) : "; echo
		mkdir -v $WORK_DIR_DEFAULT/${remotePropertiesDir##*/}
		cp -avR $remotePropertiesDir/* $WORK_DIR_DEFAULT/${remotePropertiesDir##*/}; echo
	else
		echo; echo "$scriptName :   Properties directory ($remotePropertiesDir) for remote tasks exists but contains no files, no action taken."; echo
	fi
fi

# Merge files into directory, i.e. don't replace any properties provided above
if [ -d "$remoteGenPropDir" ]; then
	echo; echo "$scriptName : Processing generated properties directory (${remoteGenPropDir}):"; echo
	if [ ! -d $WORK_DIR_DEFAULT/${remotePropertiesDir##*/} ]; then
		mkdir -v $WORK_DIR_DEFAULT/${remotePropertiesDir##*/}
	fi
	for generatedPropertyPath in $(find ${remoteGenPropDir}/ -type f); do
		generatedPropertyFile=$(basename ${generatedPropertyPath})
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${remotePropertiesDir##*/}/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> $WORK_DIR_DEFAULT/${remotePropertiesDir##*/}/${generatedPropertyFile}
	done
fi

echo; echo "$scriptName : Copy all helper scripts from remote to local : "; echo
cp -av $AUTOMATIONROOT/remote/*.sh $WORK_DIR_DEFAULT
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo "$scriptName : cp -av $AUTOMATIONROOT/remote/*.sh $WORK_DIR_DEFAULT failed! Exit code = $exitCode."
	exit $exitCode
fi

# Process Specific Local artifacts
./$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh $localArtifactListFile $WORK_DIR_DEFAULT

# 1.7.8 Process generic artifacts, i.e. applies to both local and remote
if [ -f "${SOLUTIONROOT}/storeFor" ]; then
	./$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh "${SOLUTIONROOT}/storeFor" $WORK_DIR_DEFAULT
fi

# If zipLocal property set in CDAF.solution of any build property, then a package will be created from the local takss
zipLocal=$($WORK_DIR_DEFAULT/getProperty.sh "$WORK_DIR_DEFAULT/manifest.txt" 'zipLocal')
if [ "$zipLocal" ]; then
	echo ; echo "$scriptName : Create the package (tarball) file, excluding git or svn control files"; echo
	cd $WORK_DIR_DEFAULT
	tar -zcv --exclude='.git' --exclude='.svn' -f ../$SOLUTION-$zipLocal-$BUILDNUMBER.tar.gz .
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$scriptName : tar -zcv --exclude=\'.git\' --exclude=\'.svn\' -f ../$SOLUTION-$zipLocal-$BUILDNUMBER.tar.gz . failed! Exit = $exitCode"
		exit $exitCode
	fi
	cd ..
else
	echo; echo "$scriptName : zipLocal not set in CDAF.solution of any build property, no additional action."; echo
fi