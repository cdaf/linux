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
echo "$0 :   ACTION                   : $ACTION"

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

printf "$0 :   Properties Driver        : "
propertiesDriver="$SOLUTIONROOT/properties.cm"
if [ -f $propertiesDriver ]; then
	echo "found ($propertiesDriver)"
else
	echo "none ($propertiesDriver)"
fi

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

remoteArtifactListFile="./$SOLUTIONROOT/storeForRemote"
printf "$0 :   remote artifact list     : "
if [ -f  "$remoteArtifactListFile" ]; then
	echo "found ($remoteArtifactListFile)"
else
	echo "none ($remoteArtifactListFile)"
fi

genericArtifactListFile="./$SOLUTIONROOT/storeFor"
printf "$0 :   generic artifact list    : "
if [ -f  "$genericArtifactListFile" ]; then
	echo "found ($genericArtifactListFile)"
else
	echo "none ($genericArtifactListFile)"
fi

echo "$0 :   pwd                      : $(pwd)"
echo "$0 :   hostname                 : $(hostname)"
echo "$0 :   whoami                   : $(whoami)"

cdafVersion=$($AUTOMATIONROOT/remote/getProperty.sh "$AUTOMATIONROOT/CDAF.linux" "productVersion")
echo "$0 :   CDAF Version             : $cdafVersion"

echo; echo "$0 : Clean root workspace ($(pwd))"; echo
rm -fv *.tar *.gz manifest.txt targetList

echo; echo "$0 : Remove working directories"; echo # perform explicit removal as rm -rfv is too verbose
for packageDir in $(echo "$REMOTE_WORK_DIR $LOCAL_WORK_DIR ./propertiesForRemoteTasks ./propertiesForLocalTasks"); do
	if [ -d  "${packageDir}" ]; then
		echo "removed ${packageDir}"
		rm -rf ${packageDir}
	fi
done

if [ ! -z "$ACTION" ]; then
	# case insensitive by forcing to uppercase
	testForClean=$(echo "$ACTION" | tr '[a-z]' '[A-Z]')
fi

if [ "$testForClean" == "CLEAN" ]; then
	echo; echo "$0 : Solution Workspace Clean Only"
else

	# Properties generator (added in release 1.7.8)
	if [ -f $propertiesDriver ]; then
		echo; echo "$0 : Generating properties files from ${propertiesDriver}"
		header=$(head -n 1 ${propertiesDriver})
		read -ra columns <<<"$header"
		config=$(tail -n +2 ${propertiesDriver})
		while read -r line; do
			read -ra arr <<<"$line"
			if [[ "${arr[0]}" == 'remote' ]]; then
				cdafPath="./propertiesForRemoteTasks"
			else
				cdafPath="./propertiesForLocalTasks"
			fi
			echo "$0 : Generating ${cdafPath}/${arr[1]}"
			if [ ! -d ${cdafPath} ]; then
				mkdir -p ${cdafPath}
			fi
			for i in "${!columns[@]}"; do
				if [ $i -gt 1 ]; then # do not create entries for context and target
					echo "${columns[$i]}=${arr[$i]}" >> "${cdafPath}/${arr[1]}"
				fi
			done
		done < <(echo "$config")
		if [ -d "${remotePropertiesDir}" ] && [ -d "./propertiesForRemoteTasks/" ]; then
			echo "$0 : Generated properties will be merged with any defined properties in ${remotePropertiesDir}"
		fi
		if [ -d "$SOLUTIONROOT/propertiesForLocalTasks" ] && [ -d "./propertiesForLocalTasks/" ]; then
			echo "$0 : Generated properties will be merged with any defined properties in $SOLUTIONROOT/propertiesForLocalTasks"
		fi
		
	fi

	# Process optional pre-packaging tasks (Task driver support added in release 0.7.2)
	if [ -f $prepackageTasks ]; then
		echo; echo "Process Pre-Package Tasks ..."; echo
		echo "AUTOMATIONROOT=$AUTOMATIONROOT" > ./solution.properties
		echo "SOLUTIONROOT=$SOLUTIONROOT" >> ./solution.properties
		$automationHelper/execute.sh "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$prepackageTasks" "$ACTION" 2>&1
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "$0 : Linear deployment activity ($automationHelper/execute.sh $SOLUTION $BUILDNUMBER package $SOLUTIONROOT/package.tsk) failed! Returned $exitCode"
			exit $exitCode
		fi
	fi
	
	echo "# Manifest for revision $REVISION" > manifest.txt
	echo "SOLUTION=$SOLUTION" >> manifest.txt
	echo "BUILDNUMBER=$BUILDNUMBER" >> manifest.txt
	# Process solution properties if defined
	if [ -f "$SOLUTIONROOT/CDAF.solution" ]; then
		echo; echo "$0 : CDAF.solution file found in directory \"$SOLUTIONROOT\", load solution properties"
		propertiesList=$($automationHelper/transform.sh "$SOLUTIONROOT/CDAF.solution")
		echo; echo "$propertiesList"
		cat $SOLUTIONROOT/CDAF.solution >> manifest.txt	
	fi
	echo; echo "$0 : Created manifest.txt file ..."; echo
	while read line; do echo "  $line"; done < manifest.txt
	
	echo; echo "$0 : Always create local artefacts, even if all tasks are remote"; echo
	./$AUTOMATIONROOT/buildandpackage/packageLocal.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$LOCAL_WORK_DIR" "$SOLUTIONROOT" "$AUTOMATIONROOT"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$0 : ./packageLocal.sh failed! Exit code = $exitCode."
		exit $exitCode
	fi

	# Only create the remote package if there is a remote target folder or a artefact definition list, if folder exists
	# create the remote package (even if there are no target files within it)
	if [ -d  "$remotePropertiesDir" ] || [ -f "$remoteArtifactListFile" ] || [ -f "$genericArtifactListFile" ]; then
		./$AUTOMATIONROOT/buildandpackage/packageRemote.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$REMOTE_WORK_DIR" "$SOLUTIONROOT" "$AUTOMATIONROOT"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo "$0 : ./packageRemote.sh failed! Exit code = $exitCode."
			exit $exitCode
		fi
	fi

	# Process optional post-packaging tasks (Task driver support added in release 0.8.2)
	if [ -f $postpackageTasks ]; then
		echo; echo "Process Post-Package Tasks ..."; echo
		$automationHelper/execute.sh "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$postpackageTasks" "$ACTION" 2>&1
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "$0 : Linear deployment activity ($automationHelper/execute.sh $SOLUTION $BUILDNUMBER package $SOLUTIONROOT/package.tsk) failed! Returned $exitCode"
			exit $exitCode
		fi
	fi
fi

echo; echo "$0 : --- Solution Packaging Complete ---"
