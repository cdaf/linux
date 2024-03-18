#!/usr/bin/env bash
scriptName=${0##*/}

if [ -z "$1" ]; then
	echo "[$scriptName] Solution Name not supplied. HALT!"
	exit 1
else
	SOLUTION="$1"
fi

if [ -z "$2" ]; then
	echo "[$scriptName] Build Identifier not supplied. HALT!"
	exit 2
else
	BUILDNUMBER="$2"
fi

if [ -z "$3" ]; then
	echo "[$scriptName] Source Control System Revision ID not supplied. HALT!"
	exit 3
else
	REVISION="$3"
fi

if [ -z "$4" ]; then
	echo "[$scriptName] Local Working Directory not supplied. HALT!"
	exit 4
else
	LOCAL_WORK_DIR="$4"
fi

if [ -z "$4" ]; then
	echo "[$scriptName] Local Working Directory not supplied. HALT!"
	exit 4
else
	REMOTE_WORK_DIR="$5"
fi

# Action is optional
ACTION="$6"

echo "[$scriptName] +-----------------+"
echo "[$scriptName] | Package Process |"
echo "[$scriptName] +-----------------+"
echo "[$scriptName]   SOLUTION                 : $SOLUTION"
echo "[$scriptName]   BUILDNUMBER              : $BUILDNUMBER"
echo "[$scriptName]   REVISION                 : $REVISION"
echo "[$scriptName]   LOCAL_WORK_DIR           : $LOCAL_WORK_DIR"
echo "[$scriptName]   REMOTE_WORK_DIR          : $REMOTE_WORK_DIR"
echo "[$scriptName]   ACTION                   : $ACTION"

# Look for automation root definition, if not found, default
if [ -z "$AUTOMATIONROOT" ]; then
	export AUTOMATIONROOT="$(dirname "$( cd "$(dirname "$0")" && pwd )")"
fi
echo "[$scriptName]   AUTOMATIONROOT           : $AUTOMATIONROOT"

if [ -z "$CDAF_CORE" ]; then
	export CDAF_CORE="${AUTOMATIONROOT}/remote"
fi

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "[$scriptName]   SOLUTIONROOT             : "
for directoryName in $(find . -mindepth 1 -maxdepth 1 -type d); do
	if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
		SOLUTIONROOT="$directoryName"
	fi
done
if [ -z "$SOLUTIONROOT" ]; then
	SOLUTIONROOT="$AUTOMATIONROOT/solution"
	echo "$SOLUTIONROOT (default, project directory containing CDAF.solution not found)"
else
	echo "$SOLUTIONROOT (override $SOLUTIONROOT/CDAF.solution found)"
fi

printf "[$scriptName]   Pre-package Tasks        : "
prepackageTasks="$SOLUTIONROOT/package.tsk"
if [ -f $prepackageTasks ]; then
	echo "found ($prepackageTasks)"
else
	echo "none ($prepackageTasks)"
fi

printf "[$scriptName]   Post-package Tasks       : "
postpackageTasks="$SOLUTIONROOT/wrap.tsk"
if [ -f $postpackageTasks ]; then
	echo "found ($postpackageTasks)"
else
	echo "none ($postpackageTasks)"
fi

remotePropertiesDir="$SOLUTIONROOT/propertiesForRemoteTasks"
printf "[$scriptName]   Remote Target Directory  : "
if [ -d  "$remotePropertiesDir" ]; then
	echo "found ($remotePropertiesDir)"
else
	echo "none ($remotePropertiesDir)"
fi

remoteArtifactListFile="$SOLUTIONROOT/storeForRemote"
printf "[$scriptName]   remote artifact list     : "
if [ -f  "$remoteArtifactListFile" ]; then
	echo "found ($remoteArtifactListFile)"
else
	echo "none ($remoteArtifactListFile)"
fi

containerPropertiesDir="$SOLUTIONROOT/propertiesForContainerTasks"
printf "[$scriptName]   Remote Target Directory  : "
if [ -d  "$containerPropertiesDir" ]; then
	echo "found ($containerPropertiesDir)"
else
	echo "none ($containerPropertiesDir)"
fi

genericArtifactListFile="$SOLUTIONROOT/storeFor"
printf "[$scriptName]   generic artifact list    : "
if [ -f  "$genericArtifactListFile" ]; then
	echo "found ($genericArtifactListFile)"
else
	echo "none ($genericArtifactListFile)"
fi

echo "[$scriptName]   pwd                      : $(pwd)"
echo "[$scriptName]   hostname                 : $(hostname)"
echo "[$scriptName]   whoami                   : $(whoami)"

cdafVersion=$("$AUTOMATIONROOT/remote/getProperty.sh" "$AUTOMATIONROOT/CDAF.linux" "productVersion")
echo "[$scriptName]   CDAF Version             : $cdafVersion"

packageFeatures=$("$AUTOMATIONROOT/remote/getProperty.sh" "$SOLUTIONROOT/CDAF.solution" "packageFeatures")
if [ -z "$4" ]; then
	echo "[$scriptName]   packageFeatures          : (optional property not set, option minimal)"
else
	echo "[$scriptName]   packageFeatures          : $packageFeatures (option minimal)"
fi

echo; echo "[$scriptName] Clean root workspace ($(pwd))"; echo
rm -fv *.tar *.gz targetList

echo; echo "[$scriptName] Remove working directories"; echo # perform explicit removal as rm -rfv is too verbose
for packageDir in $(echo "$REMOTE_WORK_DIR $LOCAL_WORK_DIR"); do
	if [ -d  "${packageDir}" ]; then
		echo "  removed ${packageDir}"
		rm -rf ${packageDir}
	fi
done

if [ ! -z "$ACTION" ]; then
	# case insensitive by forcing to uppercase
	testForClean=$(echo "$ACTION" | tr '[a-z]' '[A-Z]')
fi

if [ "$testForClean" == "CLEAN" ]; then
	echo; echo "[$scriptName] Solution Workspace Clean Only"
else

	echo "# Manifest for revision $SOLUTION" > manifest.txt
	echo "SOLUTION=$SOLUTION" >> manifest.txt
	echo "BUILDNUMBER=$BUILDNUMBER" >> manifest.txt
	echo "REVISION=$REVISION" >> manifest.txt

	# Process optional pre-packaging tasks (Task driver support added in release 0.7.2)
	if [ -f $prepackageTasks ]; then
		echo; echo "Process Pre-Package Tasks ..."
		"$CDAF_CORE/execute.sh" "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$prepackageTasks" "$ACTION" 2>&1
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] Linear deployment activity (\"$CDAF_CORE/execute.sh\" \"$SOLUTION\" \"$BUILDNUMBER\" \"$SOLUTIONROOT\" \"$prepackageTasks\" \"$ACTION\") failed! Returned $exitCode"
			exit $exitCode
		fi
	fi
	
	# Process solution properties if defined
	if [ -f "$SOLUTIONROOT/CDAF.solution" ]; then
		echo; echo "[$scriptName] CDAF.solution file found in directory \"$SOLUTIONROOT\", load solution properties"
		propertiesList=$("$CDAF_CORE/transform.sh" "$SOLUTIONROOT/CDAF.solution")
		echo; echo "$propertiesList"
		cat $SOLUTIONROOT/CDAF.solution >> manifest.txt	
	fi
	echo; echo "[$scriptName] Created manifest.txt file ..."; echo
	while read line; do echo "  $line"; done < manifest.txt
	
	echo; echo "[$scriptName] Always create local artefacts, even if all tasks are remote"; echo
	"$AUTOMATIONROOT/buildandpackage/packageLocal.sh" "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$LOCAL_WORK_DIR" "$SOLUTIONROOT" "$AUTOMATIONROOT"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "[$scriptName] \"$AUTOMATIONROOT/buildandpackage/packageLocal.sh\" \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$LOCAL_WORK_DIR\" \"$SOLUTIONROOT\" \"$AUTOMATIONROOT\" failed! Exit code = $exitCode."
		exit $exitCode
	fi

	# Process optional post-packaging tasks (Task driver support added in release 0.8.2)
	if [ -f $postpackageTasks ]; then
		echo; echo "Process Post-Package Tasks ..."
		"$CDAF_CORE/execute.sh" "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$postpackageTasks" "$ACTION" 2>&1
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] Linear deployment activity (\"$CDAF_CORE/execute.sh\" \"$SOLUTION\" \"$BUILDNUMBER\" \"$SOLUTIONROOT\" \"$postpackageTasks\" \"$ACTION\") failed! Returned $exitCode"
			exit $exitCode
		fi
	fi

	# 1.7.8 Only create the remote package if there is a remote target folder or a artefact definition list, if folder exists
	# create the remote package (even if there are no target files within it)
	# 2.4.0 create remote package for use in container deployment
	if [ -d  "$containerPropertiesDir" ] || [ -d  "$remotePropertiesDir" ] || [ -f "$remoteArtifactListFile" ] || [ -f "$genericArtifactListFile" ]; then
		"$AUTOMATIONROOT/buildandpackage/packageRemote.sh" "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$REMOTE_WORK_DIR" "$SOLUTIONROOT" "$AUTOMATIONROOT"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo "[$scriptName] \"$AUTOMATIONROOT/buildandpackage/packageRemote.sh\" \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$REMOTE_WORK_DIR\" \"$SOLUTIONROOT\" \"$AUTOMATIONROOT\" failed! Exit code = $exitCode."
			exit $exitCode
		fi
	fi
fi

echo; echo "[$scriptName] --- Solution Packaging Complete ---"
