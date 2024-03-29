function executeExpression {
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][ERROR][$exitCode] $1"
		exit $exitCode
	fi
}  

#!/usr/bin/env bash
scriptName='packageLocal.sh'

# Arguments are not validated in sub-scripts, only at entry point
SOLUTION="$1"
BUILDNUMBER="$2"
REVISION="$3"
WORK_DIR_DEFAULT="$4"
SOLUTIONROOT="$5"
AUTOMATIONROOT="$6"

localArtifactListFile="$SOLUTIONROOT/storeForLocal"
localPropertiesDir="$SOLUTIONROOT/propertiesForLocalTasks"
localGenPropDir="./propertiesForLocalTasks"
solutionCustomDir="$SOLUTIONROOT/custom"
localCustomDir="$SOLUTIONROOT/customLocal"
localCryptDir="$SOLUTIONROOT/cryptLocal"
cryptDir="$SOLUTIONROOT/crypt"
remotePropertiesDir="$SOLUTIONROOT/propertiesForRemoteTasks"
remoteGenPropDir="./propertiesForRemoteTasks"
containerPropertiesDir="$SOLUTIONROOT/propertiesForContainerTasks"
containerGenPropDir="./propertiesForContainerTasks"

echo "[$scriptName] --- PACKAGE locally executed scripts and artefacts ---"; echo
echo "[$scriptName]   WORK_DIR_DEFAULT               : $WORK_DIR_DEFAULT"

printf "[$scriptName]   local artifact list            : "
if [ -f  "$localArtifactListFile" ]; then
	echo "found ($localArtifactListFile)"
else
	echo "none ($localArtifactListFile)"
fi

printf "[$scriptName]   Properties for local tasks     : "
if [ -d  "$localPropertiesDir" ]; then
	echo "found ($localPropertiesDir)"
else
	echo "none ($localPropertiesDir)"
fi

printf "[$scriptName]   Generated local properties     : "
if [ -d  "$localGenPropDir" ]; then
	echo "found ($localGenPropDir)"
else
	echo "none ($localGenPropDir)"
fi

printf "[$scriptName]   local encrypted files          : "
if [ -d  "$localCryptDir" ]; then
	echo "found ($localCryptDir)"
else
	echo "none ($localCryptDir)"
fi

printf "[$scriptName]   common encrypted files         : "
if [ -d  "$cryptDir" ]; then
	echo "found ($cryptDir)"
else
	echo "none ($cryptDir)"
fi

printf "[$scriptName]   custom scripts                 : "
if [ -d  "$solutionCustomDir" ]; then
	echo "found ($solutionCustomDir)"
else
	echo "none ($solutionCustomDir)"
fi

printf "[$scriptName]   local custom scripts           : "
if [ -d  "$localCustomDir" ]; then
	echo "found ($localCustomDir)"
else
	echo "none ($localCustomDir)"
fi

printf "[$scriptName]   Properties for remote tasks    : "
if [ -d  "$remotePropertiesDir" ]; then
	echo "found ($remotePropertiesDir)"
else
	echo "none ($remotePropertiesDir)"
fi

printf "[$scriptName]   Generated remote properties    : "
if [ -d  "$remoteGenPropDir" ]; then
	echo "found ($remoteGenPropDir)"
else
	echo "none ($remoteGenPropDir)"
fi

printf "[$scriptName]   Properties for container tasks : "
if [ -d  "$containerPropertiesDir" ]; then
	echo "found ($containerPropertiesDir)"
else
	echo "none ($containerPropertiesDir)"
fi

printf "[$scriptName]   Generated container properties : "
if [ -d  "$containerGenPropDir" ]; then
	echo "found ($containerGenPropDir)"
else
	echo "none ($containerGenPropDir)"
fi

echo; echo "[$scriptName] Create $WORK_DIR_DEFAULT and seed with solution files"; echo
mkdir -v "$WORK_DIR_DEFAULT"
cp -av manifest.txt "$WORK_DIR_DEFAULT"
cp -v "$AUTOMATIONROOT/CDAF.linux" "$WORK_DIR_DEFAULT/CDAF.properties"

# 2.5.7 Support for reduced number of helper scripts to be included in release package
packageFeatures=$("$AUTOMATIONROOT/remote/getProperty.sh" "$SOLUTIONROOT/CDAF.solution" "packageFeatures")

if [ "$packageFeatures" == 'minimal' ]; then

	echo; echo "[$scriptName] packageFeatures = ${packageFeatures}"
	cp -av "$AUTOMATIONROOT/remote/getProperty.sh" "$WORK_DIR_DEFAULT"
	cp -av "$AUTOMATIONROOT/local/localTasks.sh" "$WORK_DIR_DEFAULT"
	cp -av "$AUTOMATIONROOT/remote/execute.sh" "$WORK_DIR_DEFAULT"
	cp -av "$AUTOMATIONROOT/remote/transform.sh" "$WORK_DIR_DEFAULT"
	echo

else

	# Copy all local script helpers, flat set to true to copy to root, not sub directory
	cp -avR "$AUTOMATIONROOT/local/"* "$WORK_DIR_DEFAULT"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] cp -av \"$AUTOMATIONROOT/local/*\" \"$WORK_DIR_DEFAULT\" failed! Exit code = $exitCode."
		exit $exitCode
	fi

	# Copy all remote script helpers, flat set to true to copy to root, not sub directory
	echo; echo "[$scriptName] Copy all helper scripts from remote to local : "; echo
	cp -av "$AUTOMATIONROOT/remote/"*.sh "$WORK_DIR_DEFAULT"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] cp -av \"$AUTOMATIONROOT/remote/*\"*.sh \"$WORK_DIR_DEFAULT\" failed! Exit code = $exitCode."
		exit $exitCode
	fi
fi

# Only retain either the override or default delivery process
if [ -f "$SOLUTIONROOT/delivery.sh" ]; then
	cp -avR "$SOLUTIONROOT/delivery.sh" "$WORK_DIR_DEFAULT"
else
	cp -avR "$AUTOMATIONROOT/processor/delivery.sh" "$WORK_DIR_DEFAULT"
fi

if [ -d "$localPropertiesDir" ]; then
	filesInDir=$(ls $localPropertiesDir)
	if [ ! -z "$filesInDir" ]; then

		echo; echo "[$scriptName]   Properties for local tasks ($localPropertiesDir) : "; echo
		# Copy files to driver directory and to the root directory
		mkdir -v "$WORK_DIR_DEFAULT/${localPropertiesDir##*/}"
		cp -avR $localPropertiesDir/* "$WORK_DIR_DEFAULT/${localPropertiesDir##*/}"
		cp -avR $localPropertiesDir/* "$WORK_DIR_DEFAULT/"
	else
		echo; echo "[$scriptName]   Properties directory ($localPropertiesDir) for local tasks exists but contains no files, no action taken."; echo
	fi
fi

# Merge files into directory, i.e. don't replace any properties provided above
if [ -d "$localGenPropDir" ]; then
	echo; echo "[$scriptName] Processing generated properties directory (${localGenPropDir}):"; echo
	if [ ! -d $WORK_DIR_DEFAULT/${localPropertiesDir##*/} ]; then
		mkdir -v $WORK_DIR_DEFAULT/${localPropertiesDir##*/}
	fi
	for generatedPropertyPath in $(find ${localGenPropDir}/ -type f); do
		generatedPropertyFile=$(basename ${generatedPropertyPath})
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${localPropertiesDir##*/}/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> "$WORK_DIR_DEFAULT/${localPropertiesDir##*/}/${generatedPropertyFile}"
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> "$WORK_DIR_DEFAULT/${generatedPropertyFile}"
		localGenEmpty='no'
	done
	if [ -z "$localGenEmpty" ]; then
		echo "[$scriptName][WARNING] $WORK_DIR_DEFAULT/${localPropertiesDir##*/} is empty, perhaps you have a definition without a property?"
	fi
fi

# Copy local and remote defintions
echo; echo "[$scriptName] Copy local and remote definitions"; echo
listOfTaskFile="tasksRunLocal.tsk tasksRunRemote.tsk"
for file in $listOfTaskFile; do
	if [ -f "$SOLUTIONROOT/$file" ]; then
		cp -av "$SOLUTIONROOT/$file" "$WORK_DIR_DEFAULT"
		customTasks='True'
	fi
done
if [ -z "$customTasks" ]; then
	echo "No files found for $listOfTaskFile"
fi

# 1.7.8 Merge generic tasks into explicit tasks
if [ -f "$SOLUTIONROOT/tasksRun.tsk" ]; then
	echo "'$SOLUTIONROOT/tasksRun.tsk' -> '$WORK_DIR_DEFAULT/tasksRunLocal.tsk'"
	cat "$SOLUTIONROOT/tasksRun.tsk" >> "$WORK_DIR_DEFAULT/tasksRunLocal.tsk"
fi

if [ -d "$localCryptDir" ]; then
	printf "[$scriptName]   Local encrypted files : "	
	mkdir -v "$WORK_DIR_DEFAULT/${localCryptDir##*/}/"
	cp -avR $localCryptDir/* "$WORK_DIR_DEFAULT/${localCryptDir##*/}"
fi

# CDAF 1.9.5 common encypted files
if [ -d "$cryptDir" ]; then
	printf "[$scriptName]   Local encrypted files : "	
	mkdir -v "$WORK_DIR_DEFAULT/${cryptDir##*/}"
	cp -avR $cryptDir/* "$WORK_DIR_DEFAULT/${cryptDir##*/}"
fi

# CDAF 1.7.3 Solution Custom scripts, included in Local and Remote
if [ -d "$solutionCustomDir" ]; then
	printf "[$scriptName]   Custom scripts        : "	
	cp -avR $solutionCustomDir/* "$WORK_DIR_DEFAULT/"
fi

# Copy custom scripts to root
if [ -d "$localCustomDir" ]; then
	echo; printf "[$scriptName]   Local custom scripts  : "	
	cp -avR $localCustomDir/* "$WORK_DIR_DEFAULT/"
fi

# Do not attempt to create the directory and copy files unless the source directory exists AND contains files
if [ -d "$remotePropertiesDir" ]; then
	filesInDir=$(ls $remotePropertiesDir)
	if [ ! -z "$filesInDir" ]; then
		echo; echo "[$scriptName]   Properties for remote tasks ($remotePropertiesDir) : "; echo
		mkdir -v "$WORK_DIR_DEFAULT/${remotePropertiesDir##*/}"
		cp -avR $remotePropertiesDir/* "$WORK_DIR_DEFAULT/${remotePropertiesDir##*/}"; echo
	else
		echo; echo "[$scriptName]   Properties directory ($remotePropertiesDir) for remote tasks exists but contains no files, no action taken."; echo
	fi
fi

# Merge files into directory, i.e. don't replace any properties provided above
if [ -d "$remoteGenPropDir" ]; then
	echo; echo "[$scriptName] Processing generated properties directory (${remoteGenPropDir}):"; echo
	if [ ! -d "$WORK_DIR_DEFAULT/${remotePropertiesDir##*/}" ]; then
		mkdir -v "$WORK_DIR_DEFAULT/${remotePropertiesDir##*/}"
	fi
	for generatedPropertyPath in $(find ${remoteGenPropDir}/ -type f); do
		generatedPropertyFile=$(basename ${generatedPropertyPath})
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${remotePropertiesDir##*/}/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> "$WORK_DIR_DEFAULT/${remotePropertiesDir##*/}/${generatedPropertyFile}"
		remoteGenEmpty='no'
	done
	if [ -z "$remoteGenEmpty" ]; then
		echo; echo "[$scriptName][WARNING] $WORK_DIR_DEFAULT/${remotePropertiesDir##*/} is empty, perhaps you have a definition without a property?"
	fi
fi

# 2.4.0 extend for container properties, processed locally, but using remote artefacts for execution
if [ -d "$containerGenPropDir" ]; then
	echo; echo "[$scriptName] Processing generated properties directory (${containerGenPropDir}):"; echo
	if [ ! -d "$WORK_DIR_DEFAULT/${containerPropertiesDir##*/}" ]; then
		mkdir -v "$WORK_DIR_DEFAULT/${containerPropertiesDir##*/}"
	fi
	for generatedPropertyPath in $(find ${containerGenPropDir}/ -type f); do
		generatedPropertyFile=$(basename ${generatedPropertyPath})
		echo "'${generatedPropertyPath}' -> '$WORK_DIR_DEFAULT/${containerPropertiesDir##*/}/${generatedPropertyFile}'"
		cat ${generatedPropertyPath} >> "$WORK_DIR_DEFAULT/${containerPropertiesDir##*/}/${generatedPropertyFile}"
		containerGenEmpty='no'
	done
	if [ -z "$containerGenEmpty" ]; then
		echo; echo "[$scriptName][WARNING] $WORK_DIR_DEFAULT/${remotePropertiesDir##*/} is empty, perhaps you have a definition without a property?"
	fi
fi

# Process Specific Local artifacts
executeExpression "'$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh' $localArtifactListFile '$WORK_DIR_DEFAULT' '$AUTOMATIONROOT'"

# 1.7.8 Process generic artifacts, i.e. applies to both local and remote
if [ -f "${SOLUTIONROOT}/storeFor" ]; then
	executeExpression "'$AUTOMATIONROOT/buildandpackage/packageCopyArtefacts.sh' '${SOLUTIONROOT}/storeFor' '$WORK_DIR_DEFAULT' '$AUTOMATIONROOT'"
fi

# If zipLocal property set in CDAF.solution of any build property, then a package will be created from the local tasks
zipLocal=$("$AUTOMATIONROOT/remote/getProperty.sh" "$WORK_DIR_DEFAULT/manifest.txt" 'zipLocal')
if [ "$zipLocal" ]; then
	echo ; echo "[$scriptName] Create the package (tarball) file, excluding git or svn control files"; echo
	cd "$WORK_DIR_DEFAULT"
	tar -zcv --exclude='.git' --exclude='.svn' -f ../$SOLUTION-$zipLocal-$BUILDNUMBER.tar.gz .
	cd ..
else
	echo; echo "[$scriptName] zipLocal not set in CDAF.solution of any build property, no additional action."; echo
fi