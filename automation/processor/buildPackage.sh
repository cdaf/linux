#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$scriptName : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

# Entry point for building projects and packaging solution. 

scriptName=${0##*/}

echo
echo "$scriptName : ===================================="
echo "$scriptName : Continuous Integration (CI) Starting"
echo "$scriptName : ===================================="

echo "$scriptName :   pwd             : $(pwd)"
echo "$scriptName :   hostname        : $(hostname)"
echo "$scriptName :   whoami          : $(whoami)"

# Processed out of order as needed for solution determination
AUTOMATIONROOT="$5"
if [ -z $AUTOMATIONROOT ]; then
	AUTOMATIONROOT="$(dirname $( cd "$(dirname "$0")" ; pwd -P ))"
	rootLogging="$AUTOMATIONROOT (derived from script path)"
else
	rootLogging="$AUTOMATIONROOT (passed)"
fi
export CDAF_AUTOMATION_ROOT=$AUTOMATIONROOT

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ]; then
		solutionRoot="$directoryName"
	fi
done
if [ -z "$solutionRoot" ]; then
	solutionRoot="$AUTOMATIONROOT/solution"
	solutionMessage="$solutionRoot (default, project directory containing CDAF.solution not found)"
else
	solutionMessage="$solutionRoot ($solutionRoot/CDAF.solution found)"
fi
echo "$scriptName :   solutionRoot    : $solutionMessage"

BUILDNUMBER="$1"
if [[ $BUILDNUMBER == *'$'* ]]; then
	BUILDNUMBER=$(eval echo $BUILDNUMBER)
fi
if [ -z $BUILDNUMBER ]; then
	echo "$scriptName : Build Number not passed! Exiting with code 1"; exit 1
fi
echo "$scriptName :   BUILDNUMBER     : $BUILDNUMBER"

REVISION="$2"
if [[ $REVISION == *'$'* ]]; then
	REVISION=$(eval echo $REVISION)
fi
if [ -z $REVISION ]; then
	REVISION='Revision'
	echo "$scriptName :   REVISION        : $REVISION (default)"
else
	echo "$scriptName :   REVISION        : $REVISION"
fi

ACTION="$3"
echo "$scriptName :   ACTION          : $ACTION"
caseinsensitive=$(echo "$ACTION" | tr '[A-Z]' '[a-z]')

SOLUTION="$4"
if [[ $SOLUTION == *'$'* ]]; then
	SOLUTION=$(eval echo $SOLUTION)
fi
if [ -z $SOLUTION ]; then
	SOLUTION=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "solutionName")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$scriptName : Read of SOLUTION from $solutionRoot/CDAF.solution failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "$scriptName :   SOLUTION        : $SOLUTION (derived from $solutionRoot/CDAF.solution)"
else
	echo "$scriptName :   SOLUTION        : $SOLUTION"
fi 

# Use passed argument to determine if a value was passed or if a default was set and used above
echo "$scriptName :   AUTOMATIONROOT  : $rootLogging"

LOCAL_WORK_DIR="$6"
if [ -z $LOCAL_WORK_DIR ]; then
	LOCAL_WORK_DIR='TasksLocal'
	echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR (default)"
else
	echo "$scriptName :   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"
fi

REMOTE_WORK_DIR="$7"
if [ -z $REMOTE_WORK_DIR ]; then
	REMOTE_WORK_DIR='TasksRemote'
	echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR (default)"
else
	echo "$scriptName :   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"	
fi

echo "$scriptName :   CDAF Version    : $($AUTOMATIONROOT/remote/getProperty.sh "$AUTOMATIONROOT/CDAF.linux" "productVersion")"

# If a container build command is specified, use this instead of CI process
containerBuild=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "containerBuild")
if [ ! -z "$containerBuild" ]; then
	test=$(docker --version 2>&1)
	if [[ "$test" == *"not found"* ]]; then
		echo "$scriptName :   Docker          : container Build defined in $solutionRoot/CDAF.solution, but Docker not installed, will attempt to execute natively"
		unset containerBuild
	else
		IFS=' ' read -ra ADDR <<< $test
		IFS=',' read -ra ADDR <<< ${ADDR[2]}
		dockerRun="${ADDR[0]}"
		echo "$scriptName :   Docker          : $dockerRun"
		# Test Docker is running
		echo "[$scriptName] List all current images"
		echo "docker images"
		docker images
		if [ "$?" != "0" ]; then
			if [ -z $CDAF_DOCKER_REQUIRED ]; then
				echo "$scriptName : Docker installed but not running, will attempt to execute natively (set CDAF_DOCKER_REQUIRED if docker is mandatory)"
				unset containerBuild
			else
				echo "$scriptName : Docker installed but not running, CDAF_DOCKER_REQUIRED is set so will try and start"
				if [ $(whoami) != 'root' ];then
					elevate='sudo'
				fi
				executeExpression "$elevate service docker start"
				executeExpression "$elevate service docker status"
			fi
		fi
	fi
else
	echo "$scriptName :   containerBuild  : (not defined in $solutionRoot/CDAF.solution)"
fi

# Support for image as an environment variable, do not overwrite if already set
containerImage=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "containerImage")
if [ -z "$containerImage" ]; then
	echo "$scriptName :   containerImage  : (not defined in $solutionRoot/CDAF.solution)"
else
	if [ -z $CONTAINER_IMAGE ]; then
		export CONTAINER_IMAGE="$containerImage"
		echo "$scriptName :   CONTAINER_IMAGE : $CONTAINER_IMAGE (set to \$containerImage)"
	else
		echo "$scriptName :   containerImage  : $containerImage"
		echo "$scriptName :   CONTAINER_IMAGE : $CONTAINER_IMAGE (not changed as already set)"
	fi
fi

configManagementList=$(find $solutionRoot -mindepth 1 -maxdepth 1 -type f -name "*.cm")
if [ -z "$configManagementList" ]; then
	echo "$scriptName :   CM Driver       : none ($solutionRoot/*.cm)"
else
	for propertiesDriver in $configManagementList; do
		echo "$scriptName :   CM Driver       : $propertiesDriver"
	done
fi

pivotList=$(find $solutionRoot -mindepth 1 -maxdepth 1 -type f -name "*.pv")
if [ -z "$pivotList" ]; then
	echo "$scriptName :   PV Driver       : none ($solutionRoot/*.pv)"
else
	for propertiesDriver in $pivotList; do
		echo "$scriptName :   PV Driver       : $propertiesDriver"
	done
fi

echo; echo "$scriptName : Remove working directories"; echo # perform explicit removal as rm -rfv is too verbose
for packageDir in $(echo "./propertiesForRemoteTasks ./propertiesForLocalTasks"); do
	if [ -d  "${packageDir}" ]; then
		echo "  removed ${packageDir}"
		rm -rf ${packageDir}
	fi
done

# Properties generator (added in release 1.7.8, extended to list in 1.8.11)
for propertiesDriver in $configManagementList; do
	echo; echo "$scriptName : Generating properties files from ${propertiesDriver}"
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
		echo "$scriptName :   Generating ${cdafPath}/${arr[1]}"
		if [ ! -d ${cdafPath} ]; then
			mkdir -p ${cdafPath}
		fi
		for i in "${!columns[@]}"; do
			if [ $i -gt 1 ]; then # do not create entries for context and target
				if [ ! -z "${arr[$i]}" ]; then
					echo "${columns[$i]}=${arr[$i]}" >> "${cdafPath}/${arr[1]}"
				fi
			fi
		done
	done < <(echo "$config")
done

# 1.9.3 add pivoted CM table support
for propertiesDriver in $pivotList; do
	echo; echo "$scriptName : Generating properties files from ${propertiesDriver}"
	IFS=$'\r\n' GLOBIGNORE='*' command eval 'rows=($(cat $propertiesDriver))'
	read -ra columns <<<"${rows[0]}"
	read -ra paths <<<"${rows[1]}"
	for (( i=2; i<=${#rows[@]}; i++ )); do
		read -ra arr <<<"${rows[$i]}"
		for (( j=1; j<=${#arr[@]}; j++ )); do
			if [ ! -z "${columns[$j]}" ] && [ ! -z "${arr[$j]}" ] ; then
				if [[ "${paths[$j]}" == 'remote' ]]; then
					cdafPath="./propertiesForRemoteTasks"
				else
					cdafPath="./propertiesForLocalTasks"
				fi
				if [ ! -d "${cdafPath}" ]; then
					mkdir -p ${cdafPath}
				fi
				if [ ! -f "${cdafPath}/${columns[$j]}" ]; then
					echo "$scriptName :   Generating ${cdafPath}/${columns[$j]}"
				fi
				echo "${arr[0]}=${arr[$j]}" >> "${cdafPath}/${columns[$j]}"
			fi
		done
	done
done

# CDAF 1.7.0 Container Build process
if [ ! -z "$containerBuild" ] && [ "$caseinsensitive" != "clean" ] && [ "$caseinsensitive" != "packageonly" ]; then
	echo
	echo "$scriptName Execute Container build, this performs cionly, options clean and packageonly are ignored."
	executeExpression "$containerBuild"

	imageBuild=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "imageBuild")
	if [ ! -z "$containerBuild" ]; then
		echo
		echo "$scriptName Execute Image build, as defined for imageBuild in $solutionRoot/CDAF.solution"
		executeExpression "$imageBuild"
	else
		echo "$scriptName :   imageBuild      : (not defined in $solutionRoot/CDAF.solution)"
	fi
else
	if [ "$caseinsensitive" == "packageonly" ]; then
		echo; echo "$scriptName action is ${ACTION}, do not perform build."
	else
		$AUTOMATIONROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$ACTION"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo
			echo "$scriptName : Project(s) Build Failed! $AUTOMATIONROOT/buildandpackage/buildProjects.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$ACTION\". Halt with exit code = $exitCode. "
			exit $exitCode
		fi
	fi
	
	if [ "$caseinsensitive" == "buildonly" ]; then
		echo "$scriptName action is ${ACTION}, do not perform package."
	else
		$AUTOMATIONROOT/buildandpackage/package.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR" "$ACTION"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo
			echo "$scriptName : Solution Package Failed! $AUTOMATIONROOT/buildandpackage/package.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$LOCAL_WORK_DIR\" \"$REMOTE_WORK_DIR\" \"$ACTION\". Halt with exit code = $exitCode."
			exit $exitCode
		fi
	fi
fi

artifactPrefix=$($AUTOMATIONROOT/remote/getProperty.sh "$solutionRoot/CDAF.solution" "artifactPrefix")
if [ ! -z $artifactPrefix ]; then
	artifactID="${SOLUTION}-${artifactPrefix}.${BUILDNUMBER}"
	echo; echo "[$scriptName] artifactPrefix = $artifactID, generate single file artefact ..."
	if [ -f "${SOLUTION}-${BUILDNUMBER}.tar.gz" ]; then
	    tar -czf $artifactID.tar.gz TasksLocal/ ${SOLUTION}-${BUILDNUMBER}.tar.gz
	else
	    tar -czf $artifactID.tar.gz TasksLocal/
	fi

	echo "[$scriptName]   Create single script artefact release.sh"
	echo '#!/usr/bin/env bash' > release.sh
  	echo 'ENVIRONMENT="$1"' >> release.sh
  	echo 'RELEASE="$2"' >> release.sh
  	echo 'OPT_ARG="$3"' >> release.sh
  	echo "SOLUTION=$SOLUTION" >> release.sh
  	echo "echo; echo 'Launching release.sh (${artifactPrefix}.${BUILDNUMBER}) ...'" >> release.sh
  	echo 'if [ -d "TasksLocal" ]; then rm -rf "TasksLocal"; fi' >> release.sh
  	echo 'for packageFile in $(find . -maxdepth 1 -type f -name "${SOLUTION}-*.gz"); do rm $packageFile; done' >> release.sh
	echo "base64 -d << EOF | tar -xzf -" >> release.sh
	base64 $artifactID.tar.gz >> release.sh
	echo 'EOF' >> release.sh
	echo './TasksLocal/delivery.sh "$ENVIRONMENT" "$RELEASE" "$OPT_ARG"' >> release.sh
	echo "[$scriptName]   Set resulting package file executable"
	executeExpression "chmod +x release.sh"
fi

if [[ "$ACTION" == "staging@"* ]]; then # Primarily for Microsoft ADO & IBM BlueMix
	IFS='@' read -ra arr <<< $ACTION
	if [ ! -d "${arr[1]}" ]; then
		executeExpression "mkdir -p '${arr[1]}'"
	fi
	if [ -z $artifactPrefix ]; then
		executeExpression "cp -rf './TasksLocal/' '${arr[1]}'"
		for packageFile in $(find . -maxdepth 1 -type f -name "${SOLUTION}-*.gz"); do
			executeExpression "cp -f '${packageFile}' '${arr[1]}'"
		done
	else
		executeExpression "cp -f 'release.sh' '${arr[1]}'"
	fi
fi

executeExpression "rm -rf propertiesForLocalTasks"
if [ -d "TasksRemote" ]; then
	executeExpression "rm -rf TasksRemote"
fi
if [ -d "propertiesForRemoteTasks" ]; then
	executeExpression "rm -rf propertiesForRemoteTasks"
fi

echo; echo "$scriptName : Continuous Integration (CI) Finished"
exit 0
