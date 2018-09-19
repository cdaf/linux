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
localGenPropDir="./propertiesForLocalTasks"
solutionCustomDir="$SOLUTIONROOT/custom"
localCustomDir="$SOLUTIONROOT/customLocal"
localCryptDir="$SOLUTIONROOT/cryptLocal"
remotePropertiesDir="$SOLUTIONROOT/propertiesForRemoteTasks"
remoteGenPropDir="./propertiesForLocalTasks"

echo "$0 : --- PACKAGE locally executed scripts and artefacts ---"; echo
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

printf "$0 :   Generated local properties  : "
if [ -d  "$localGenPropDir" ]; then
	echo "found ($localGenPropDir)"
else
	echo "none ($localGenPropDir)"
fi

printf "$0 :   local encrypted files       : "
if [ -d  "$localCryptDir" ]; then
	echo "found ($localCryptDir)"
else
	echo "none ($localCryptDir)"
fi

printf "$0 :   custom scripts              : "
if [ -d  "$solutionCustomDir" ]; then
	echo "found ($solutionCustomDir)"
else
	echo "none ($solutionCustomDir)"
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

printf "$0 :   Generated remote properties : "
if [ -d  "$remoteGenPropDir" ]; then
	echo "found ($remoteGenPropDir)"
else
	echo "none ($remoteGenPropDir)"
fi

echo; echo "$0 : Create working directory and seed with solution files"; echo
mkdir -v $WORK_DIR_DEFAULT
cp -av manifest.txt $WORK_DIR_DEFAULT
cp -v $AUTOMATIONROOT/CDAF.linux $WORK_DIR_DEFAULT/CDAF.properties

echo; echo "$0 : Copy required local scripts"; echo
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

		echo; echo "$0 :   Properties for local tasks ($localPropertiesDir) : "; echo
		# Copy files to driver directory and to the root directory
		mkdir -v $WORK_DIR_DEFAULT/${localPropertiesDir##*/}
		cp -avR $localPropertiesDir/* $WORK_DIR_DEFAULT/${localPropertiesDir##*/}
		cp -avR $localPropertiesDir/* $WORK_DIR_DEFAULT/

		# Include remote tasks should they be required for re-use as local tasks
		if [ -f "$SOLUTIONROOT/tasksRunRemote.tsk" ]; then
			cp -av $SOLUTIONROOT/tasksRunRemote.tsk $WORK_DIR_DEFAULT
		fi				
	else
		echo; echo "$0 :   Properties directory ($localPropertiesDir) for local tasks exists but contains no files, no action taken."; echo
	fi
fi

# Merge files into directory, i.e. don't replace any properties provided above
if [ -d "$localGenPropDir" ]; then
	echo; echo "$0 :   Processing generated properties directory (./propertiesForLocalTasks):"; echo
	for generatedPropertyPath in $(find ./propertiesForLocalTasks/ -type f); do
		generatedPropertyFile=$(basename ${generatedPropertyPath})
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${localPropertiesDir##*/}/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> $WORK_DIR_DEFAULT/${localPropertiesDir##*/}/${generatedPropertyFile}
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> $WORK_DIR_DEFAULT/${generatedPropertyFile}
	done
fi

# If there are properties files but no default task, log a warning (not an error because may have override tasks defined in properties files themselves)
filesInDir=$(ls $WORK_DIR_DEFAULT/${localPropertiesDir##*/})
if [ -n "$filesInDir" ] && [ -f "$SOLUTIONROOT/tasksRunLocal.tsk" ]; then
	cp -av $SOLUTIONROOT/tasksRunLocal.tsk $WORK_DIR_DEFAULT
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$0 : cp -av $SOLUTIONROOT/tasksRunLocal.tsk $WORK_DIR_DEFAULT failed! Exit code = $exitCode."
		exit $exitCode
	fi
else
	echo; echo "$0 : Warning : Default Task ($SOLUTIONROOT/tasksRunLocal.tsk) not found, override task must be defined for each properties file."
fi

if [ -d "$localCryptDir" ]; then
	printf "$0 :   Local encrypted files : "	
	mkdir -v $WORK_DIR_DEFAULT/${localCryptDir##*/}
	cp -avR $localCryptDir/* $WORK_DIR_DEFAULT/${localCryptDir##*/}
fi

# CDAF 1.7.3 Solution Custom scripts, included in Local and Remote
if [ -d "$solutionCustomDir" ]; then
	printf "$0 :   Custom scripts        : "	
	cp -avR $solutionCustomDir/* $WORK_DIR_DEFAULT/
fi

# Copy custom scripts to root
if [ -d "$localCustomDir" ]; then
	printf "$0 :   Local custom scripts  : "	
	cp -avR $localCustomDir/* $WORK_DIR_DEFAULT/
fi

# Do not attempt to create the directory and copy files unless the source directory exists AND contains files
if [ -d "$remotePropertiesDir" ]; then
	filesInDir=$(ls $remotePropertiesDir)
	if [ -n "$filesInDir" ]; then
		echo; echo "$0 :   Properties for remote tasks ($remotePropertiesDir) : "; echo
		mkdir -v $WORK_DIR_DEFAULT/${remotePropertiesDir##*/}
		cp -avR $remotePropertiesDir/* $WORK_DIR_DEFAULT/${remotePropertiesDir##*/}; echo
	else
		echo; echo "$0 :   Properties directory ($remotePropertiesDir) for remote tasks exists but contains no files, no action taken."; echo
	fi
fi

# Merge files into directory, i.e. don't replace any properties provided above
if [ -d "$remoteGenPropDir" ]; then
	echo; echo "$0 :   Processing generated properties directory (./propertiesForRemoteTasks):"; echo
	for generatedPropertyPath in $(find ./propertiesForRemoteTasks/ -type f); do
		generatedPropertyFile=$(basename ${generatedPropertyPath})
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${remotePropertiesDir##*/}/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> $WORK_DIR_DEFAULT/${remotePropertiesDir##*/}/${generatedPropertyFile}
	done
fi

echo "$0 :   Copy all helper scripts from remote to local : "; echo
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

# If zipLocal property set in CDAF.solution of any build property, then a package will be created from the local takss
zipLocal=$($WORK_DIR_DEFAULT/getProperty.sh "$WORK_DIR_DEFAULT/manifest.txt" 'zipLocal')
if [ "$zipLocal" ]; then
	echo ; echo "$0 : Create the package (tarball) file, excluding git or svn control files"; echo
	cd $WORK_DIR_DEFAULT
	tar -zcv --exclude='.git' --exclude='.svn' -f ../$SOLUTION-$zipLocal-$BUILDNUMBER.tar.gz .
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$0 : tar -zcv --exclude=\'.git\' --exclude=\'.svn\' -f ../$SOLUTION-$zipLocal-$BUILDNUMBER.tar.gz . failed! Exit = $exitCode"
		exit $exitCode
	fi
	cd ..
else
	echo; echo "$0 : zipLocal not set in CDAF.solution of any build property, no additional action."; echo
fi