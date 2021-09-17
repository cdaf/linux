#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

function executeWarnRetry {
	counter=1
	max=3
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		output=$(eval "$1 2>&1")
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			if [[ "$output" == *'file changed as we read it'* ]]; then
				echo "[$scriptName][WARN] $output"
				success='yes'
			else			
				echo "[$scriptName][ERROR] $output"
				counter=$((counter + 1))
				if [ "$counter" -le "$max" ]; then
					echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
				else
					echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
					exit $exitCode
				fi
			fi					 
		else
			echo "[$scriptName][INFO] $output"
			success='yes'
		fi
	done
}

# 2.4.1 Use the function call to separate fields, this allows support for whitespace and quote wrapped values
function cmProperties {
	cmline=()
	for argument in "${@}"; do
		cmline+=("$argument")
	done
	if [[ ! -z "${cmline[0]}" ]]; then
		if [[ "${cmline[0]}" == 'remote' ]]; then
			cdafPath="./propertiesForRemoteTasks"
		elif [[ "${cmline[0]}" == 'local' ]]; then
			cdafPath="./propertiesForLocalTasks"
		elif [[ "${cmline[0]}" == 'container' ]]; then
			cdafPath="./propertiesForContainerTasks"
		else
			echo "[$scriptName] Unknown CM context ${cmline[0]}, supported contexts are rempote, local or container"
			exit 5922
		fi
		echo "[$scriptName]   Generating ${cdafPath}/${cmline[1]}"
		if [ ! -d ${cdafPath} ]; then
			mkdir -p ${cdafPath}
		fi
		for i in "${!columns[@]}"; do
			if [ $i -gt 1 ]; then # do not create entries for context and target
				if [ ! -z "${cmline[$i]}" ]; then
					echo "${columns[$i]}=${cmline[$i]}" >> "${cdafPath}/${cmline[1]}"
				fi
			fi
		done
	fi
}

# 2.4.1 Use the function call to separate fields, this allows support for whitespace and quote wrapped values
function pvProperties {
	pvline=()
	for argument in "${@}"; do
		pvline+=("$argument")
	done
	for (( j=1; j<=${#pvline[@]}; j++ )); do
		if [ ! -z "${columns[$j]}" ] && [ ! -z "${pvline[$j]}" ] ; then
			if [[ "${columns[$j]}" == 'remote' ]]; then
				cdafPath="./propertiesForRemoteTasks"
			elif [[ "${columns[$j]}" == 'local' ]]; then
				cdafPath="./propertiesForLocalTasks"
			elif [[ "${columns[$j]}" == 'container' ]]; then
				cdafPath="./propertiesForContainerTasks"
			else
				echo "[$scriptName] Unknown PV context ${cmline[0]}, supported contexts are rempote, local or container"
				exit 5923
			fi
			if [ ! -d "${cdafPath}" ]; then
				mkdir -p ${cdafPath}
			fi
			if [ ! -f "${cdafPath}/${paths[$j]}" ]; then
				echo "[$scriptName]   Generating ${cdafPath}/${paths[$j]}"
			fi
			echo "${pvline[0]}=${pvline[$j]}" >> "${cdafPath}/${paths[$j]}"
		fi
	done
}

# Entry point for building projects and packaging solution. 
scriptName='buildPackage.sh'

echo; echo "[$scriptName] ===================================="
echo "[$scriptName] Continuous Integration (CI) Starting"
echo "[$scriptName] ===================================="

# Processed out of order as needed for solution determination
AUTOMATIONROOT="$5"
if [ -z $AUTOMATIONROOT ]; then
	AUTOMATIONROOT="$(dirname $( cd "$(dirname "$0")" && pwd ))"
	rootLogging="$AUTOMATIONROOT (derived from script path)"
else
	rootLogging="$AUTOMATIONROOT (passed)"
fi
export CDAF_AUTOMATION_ROOT=$AUTOMATIONROOT

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ]; then
		SOLUTIONROOT="$directoryName"
	fi
done
if [ -z "$SOLUTIONROOT" ]; then
	SOLUTIONROOT="$AUTOMATIONROOT/solution"
	solutionMessage="$SOLUTIONROOT (default, project directory containing CDAF.solution not found)"
else
	solutionMessage="$SOLUTIONROOT ($SOLUTIONROOT/CDAF.solution found)"
fi
echo "[$scriptName]   SOLUTIONROOT    : $solutionMessage"

BUILDNUMBER="$1"
if [[ $BUILDNUMBER == *'$'* ]]; then
	BUILDNUMBER=$(eval echo $BUILDNUMBER)
fi
if [ -z $BUILDNUMBER ]; then
	echo "[$scriptName] Build Number not passed! Exiting with code 1"; exit 5921
fi
echo "[$scriptName]   BUILDNUMBER     : $BUILDNUMBER"

REVISION="$2"
if [[ $REVISION == *'$'* ]]; then
	REVISION=$(eval echo $REVISION)
fi
REVISION=${REVISION##*/}                                  # strip to basename
REVISION=$(sed 's/[^[:alnum:]]\+//g' <<< $REVISION)       # remove non-alphnumeric
REVISION=$(echo "$REVISION" | tr '[:upper:]' '[:lower:]') # make branch names case insentive
if [ -z $REVISION ]; then
	REVISION='feature'
	echo "[$scriptName]   REVISION        : $REVISION (default)"
else
	echo "[$scriptName]   REVISION        : $REVISION"
fi

ACTION="$3"
echo "[$scriptName]   ACTION          : $ACTION"
caseinsensitive=$(echo "$ACTION" | tr '[A-Z]' '[a-z]')

SOLUTION="$4"
if [[ $SOLUTION == *'$'* ]]; then
	SOLUTION=$(eval echo $SOLUTION)
fi
if [ -z $SOLUTION ]; then
	SOLUTION=$($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "solutionName")
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Read of SOLUTION from $SOLUTIONROOT/CDAF.solution failed! Returned $exitCode"
		exit $exitCode
	fi
	echo "[$scriptName]   SOLUTION        : $SOLUTION (derived from $SOLUTIONROOT/CDAF.solution)"
else
	echo "[$scriptName]   SOLUTION        : $SOLUTION"
fi 

# Use passed argument to determine if a value was passed or if a default was set and used above
echo "[$scriptName]   AUTOMATIONROOT  : $rootLogging"

LOCAL_WORK_DIR="$6"
if [ -z $LOCAL_WORK_DIR ]; then
	LOCAL_WORK_DIR='TasksLocal'
	echo "[$scriptName]   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR (default)"
else
	echo "[$scriptName]   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"
fi

REMOTE_WORK_DIR="$7"
if [ -z $REMOTE_WORK_DIR ]; then
	REMOTE_WORK_DIR='TasksRemote'
	echo "[$scriptName]   REMOTE_WORK_DIR : $REMOTE_WORK_DIR (default)"
else
	echo "[$scriptName]   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"
fi

printf "[$scriptName]   Pre-build Task  : "
prebuildTasks="$SOLUTIONROOT/prebuild.tsk"
if [ -f $prebuildTasks ]; then
	echo "found ($prebuildTasks)"
else
	echo "none ($prebuildTasks)"
fi

printf "[$scriptName]   Post-build Task : "
postbuild="$SOLUTIONROOT/postbuild.tsk"
if [ -f $postbuild ]; then
	echo "found ($postbuild)"
else
	echo "none ($postbuild)"
fi

echo "[$scriptName]   pwd             : $(pwd)"
echo "[$scriptName]   hostname        : $(hostname)"
echo "[$scriptName]   whoami          : $(whoami)"

echo "[$scriptName]   CDAF Version    : $($AUTOMATIONROOT/remote/getProperty.sh "$AUTOMATIONROOT/CDAF.linux" "productVersion")"

# Process optional post-packaging tasks (Task driver support added in release 2.4.4)
if [ -f $prebuildTasks ] && [[ "$ACTION" != 'container_build' ]]; then

	# Set properties for execution engine
	echo "PROJECT=${projectName}" > ../build.properties
	echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ../build.properties
	echo "SOLUTIONROOT=$SOLUTIONROOT" >> ../build.properties

	echo; echo "Process Pre-Build Tasks ..."
	$AUTOMATIONROOT/remote/execute.sh "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$prebuildTasks" "$ACTION" 2>&1
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Linear deployment activity ($AUTOMATIONROOT/remote/execute.sh $SOLUTION $BUILDNUMBER package $SOLUTIONROOT/package.tsk) failed! Returned $exitCode"
		exit $exitCode
	fi
fi

# If a container build command is specified, use this instead of CI process
if [[ "$ACTION" == 'container_build' ]]; then
	echo; echo "[$scriptName] \$ACTION = $ACTION, container build detection skipped ..."; echo
else
	containerBuild=$($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "containerBuild")
	if [ ! -z "$containerBuild" ]; then
		if [ ! -z $CDAF_SKIP_CONTAINER_BUILD ] || [[ "$ACTION" == 'skip_container_build' ]]; then
			echo; echo "[$scriptName] \$ACTION = $ACTION, container build defined (${containerBuild}) but skipped ..."; echo
			unset containerBuild
		else
			test=$(docker --version 2>&1)
			if [ $? -ne 0 ]; then
				echo "[$scriptName]   Docker          : containerBuild defined in $SOLUTIONROOT/CDAF.solution, but Docker not installed, will attempt to execute natively"
				unset containerBuild
			else
				IFS=' ' read -ra ADDR <<< $test
				IFS=',' read -ra ADDR <<< ${ADDR[2]}
				dockerRun="${ADDR[0]}"
				echo "[$scriptName]   Docker          : $dockerRun"
				# Test Docker is running
				echo "[$scriptName] List all current images"
				echo "docker images"
				docker images
				if [ "$?" != "0" ]; then
					if [ -z $CDAF_DOCKER_REQUIRED ]; then
						echo "[$scriptName] Docker installed but not running, will attempt to execute natively (set CDAF_DOCKER_REQUIRED if docker is mandatory)"
						unset containerBuild
					else
						echo "[$scriptName] Docker installed but not running, CDAF_DOCKER_REQUIRED is set so will try and start"
						if [ $(whoami) != 'root' ];then
							elevate='sudo'
						fi
						executeExpression "$elevate service docker start"
						executeExpression "$elevate service docker status"
					fi
				fi
			fi
		fi
	else
		echo "[$scriptName]   containerBuild  : (not defined in $SOLUTIONROOT/CDAF.solution)"
	fi
fi

# 2.2.0 Image Build as incorperated function
imageBuild=$($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "imageBuild")
if [ -z "$imageBuild" ]; then
	echo "[$scriptName]   imageBuild      : (not defined in $SOLUTIONROOT/CDAF.solution)"
else
	echo "[$scriptName]   imageBuild      : $imageBuild"
fi

# Support for image as an environment variable, do not overwrite if already set
containerImage=$($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "containerImage")
if [ -z "$containerImage" ]; then
	echo "[$scriptName]   containerImage  : (not defined in $SOLUTIONROOT/CDAF.solution)"
else
	if [ -z $CONTAINER_IMAGE ]; then
		export CONTAINER_IMAGE="$containerImage"
		echo "[$scriptName]   CONTAINER_IMAGE : $CONTAINER_IMAGE (set to \$containerImage)"
	else
		echo "[$scriptName]   containerImage  : $containerImage"
		echo "[$scriptName]   CONTAINER_IMAGE : $CONTAINER_IMAGE (not changed as already set)"
	fi
fi

# Properties generator (added in release 1.7.8, extended to list in 1.8.11, moved from build to pre-process 1.8.14), added container tasks 2.4.0
echo; echo "[$scriptName] Remove working directories"; echo # perform explicit removal as rm -rfv is too verbose
for packageDir in $(echo "./propertiesForRemoteTasks ./propertiesForLocalTasks ./propertiesForContainerTasks"); do
	if [ -d  "${packageDir}" ]; then
		echo "  removed ${packageDir}"
		rm -rf ${packageDir}
	fi
done

configManagementList=$(find $SOLUTIONROOT -mindepth 1 -maxdepth 1 -type f -name "*.cm")
if [ -z "$configManagementList" ]; then
	echo "[$scriptName]   CM Driver       : none ($SOLUTIONROOT/*.cm)"
else
	for propertiesDriver in $configManagementList; do
		echo "[$scriptName]   CM Driver       : $propertiesDriver"
	done
fi

pivotList=$(find $SOLUTIONROOT -mindepth 1 -maxdepth 1 -type f -name "*.pv")
if [ -z "$pivotList" ]; then
	echo "[$scriptName]   PV Driver       : none ($SOLUTIONROOT/*.pv)"
else
	for propertiesDriver in $pivotList; do
		echo "[$scriptName]   PV Driver       : $propertiesDriver"
	done
fi

# Process table with properties as fields and environments as rows, 2.4.0 extend for propertiesForContainerTasks
for propertiesDriver in $configManagementList; do
	echo; echo "[$scriptName] Generating properties files from ${propertiesDriver}"
	header=$(head -n 1 ${propertiesDriver})
	read -ra columns <<<"$header"
	export $columns
	config=$(tail -n +2 ${propertiesDriver})
	while read -r line; do
		line=$(echo ${line//$/\\$})
		eval "cmProperties $line"
	done < <(echo "$config")
done

# 1.9.3 add pivoted CM table support, with properties as rows and environments as fields, 2.4.0 extend for propertiesForContainerTasks
for propertiesDriver in $pivotList; do
	echo; echo "[$scriptName] Generating properties files from ${propertiesDriver}"
	IFS=$'\r\n' GLOBIGNORE='*' command eval 'pvfile=($(cat $propertiesDriver))'
	declare -i i=0
	for pvrow in "${pvfile[@]}"; do
		if [ "$i" -eq "0" ]; then
			read -ra columns <<<"${pvrow}"
			export $columns
		elif [ "$i" -eq "1" ]; then
			read -ra paths <<<"${pvrow}"
			export $paths
		else
			line=$(echo ${pvrow//$/\\$})
			eval "pvProperties ${line}"
		fi
		i+=1
	done
done

# CDAF 1.7.0 Container Build process
if [ ! -z "$containerBuild" ] && [ "$caseinsensitive" != "clean" ] && [ "$caseinsensitive" != "packageonly" ]; then
	echo; echo "[$scriptName] Execute Container build, this performs cionly, options clean and packageonly are ignored."
	executeExpression "$containerBuild"
else
	if [ "$caseinsensitive" == "packageonly" ]; then
		echo; echo "[$scriptName] action is ${ACTION}, do not perform build."
	else
		$AUTOMATIONROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$ACTION"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo
			echo "[$scriptName] Project(s) Build Failed! $AUTOMATIONROOT/buildandpackage/buildProjects.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$ACTION\". Halt with exit code = $exitCode. "
			exit $exitCode
		fi
	fi
	
	if [ "$caseinsensitive" == "buildonly" ]; then
		echo "[$scriptName] action is ${ACTION}, do not perform package."
	else
		$AUTOMATIONROOT/buildandpackage/package.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR" "$ACTION"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo
			echo "[$scriptName] Solution Package Failed! $AUTOMATIONROOT/buildandpackage/package.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$LOCAL_WORK_DIR\" \"$REMOTE_WORK_DIR\" \"$ACTION\". Halt with exit code = $exitCode."
			exit $exitCode
		fi
	fi
fi

# CDAF 2.1.0 Self-extracting Script Artifact
if [[ "$ACTION" != 'container_build' ]]; then
	artifactPrefix=$($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "artifactPrefix")
	if [ ! -z $artifactPrefix ]; then
		artifactID="${SOLUTION}-${artifactPrefix}.${BUILDNUMBER}"
		echo; echo "[$scriptName] artifactPrefix = $artifactID, generate single file artefact ..."
		if [ -f "${SOLUTION}-${BUILDNUMBER}.tar.gz" ]; then
			executeWarnRetry "tar -czf $artifactID.tar.gz TasksLocal/ ${SOLUTION}-${BUILDNUMBER}.tar.gz"
		else
			executeWarnRetry "tar -czf $artifactID.tar.gz TasksLocal/"
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

if [[ "$ACTION" != 'container_build' ]]; then

	# Process optional post-packaging tasks (Task driver support added in release 2.4.4)
	if [ -f $postbuild ]; then

		# Set properties for execution engine
		echo "PROJECT=${projectName}" > ../build.properties
		echo "AUTOMATIONROOT=$AUTOMATIONROOT" >> ../build.properties
		echo "SOLUTIONROOT=$SOLUTIONROOT" >> ../build.properties

		echo; echo "Process Post-Build Tasks ..."
		$AUTOMATIONROOT/remote/execute.sh "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$postbuild" "$ACTION" 2>&1
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] Linear deployment activity ($AUTOMATIONROOT/remote/execute.sh $SOLUTION $BUILDNUMBER package $SOLUTIONROOT/package.tsk) failed! Returned $exitCode"
			exit $exitCode
		fi
	fi

	# 2.2.0 Image Build as incorperated function, no longer conditional on containerBuild, but do not attempt if within containerbuild
	if [ ! -z "$imageBuild" ]; then

		echo
		echo "[$scriptName] Execute image build ..."
		test=$(docker --version 2>&1)
		if [[ $? -ne 0 ]]; then
			echo "[$scriptName] imageBuild defined in $SOLUTIONROOT/CDAF.solution, but Docker not installed, skipping ..."
		else
			runtimeImage=$($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "runtimeImage")
			if [ ! -z "$runtimeImage" ]; then
				echo "[$scriptName]   runtimeImage  = $runtimeImage"
			else
				runtimeImage=$($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "containerImage")
				if [ ! -z "$runtimeImage" ]; then
					echo "[$scriptName]   containerImage = $containerImage (runtimeImage not defined in $SOLUTIONROOT/CDAF.solution)"
				else
					if [ -z "$CONTAINER_IMAGE" ]; then
						echo "[$scriptName][WARN] neither runtimeImage nor runtimeImage defined in $SOLUTIONROOT/CDAF.solution, assuming a hardcoded image will be used."
					else
						runtimeImage=$CONTAINER_IMAGE
						echo "[$scriptName]   runtimeImage  = $runtimeImage (neither runtimeImage nor runtimeImage defined in $SOLUTIONROOT/CDAF.solution, however Environment Variable CONTAINER_IMAGE set)"
					fi
				fi
			fi
			constructor=$($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "constructor")
			if [ ! -z "$constructor" ]; then
				echo "[$scriptName]   constructor   = $constructor"
			fi

			# 2.2.0 Integrated Function using environment variables
			defaultBranch=$($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "defaultBranch")
			if [ -z "$defaultBranch" ]; then
				defaultBranch='master'
			else
				echo "[$scriptName]   defaultBranch = $defaultBranch"
			fi
			if [ $REVISION == $defaultBranch ]; then
				export CDAF_REGISTRY_URL=$(eval "echo $($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "CDAF_REGISTRY_URL")")
				export CDAF_REGISTRY_TAG=$(eval "echo $($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "CDAF_REGISTRY_TAG")")
				export CDAF_REGISTRY_USER=$(eval "echo $($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "CDAF_REGISTRY_USER")")
				export CDAF_REGISTRY_TOKEN=$(eval "echo $($AUTOMATIONROOT/remote/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "CDAF_REGISTRY_TOKEN")")
			fi
			executeExpression "$imageBuild"
		fi
	fi

	# CDAF 2.1.0 Self-extracting Script Artifact
	if [ ! -z $artifactPrefix ]; then
		executeExpression "rm -rf TasksLocal"
		executeExpression "rm -rf propertiesForLocalTasks"
		for packageFile in $(find . -maxdepth 1 -type f -name "${SOLUTION}-*.gz"); do
			executeExpression "rm '${packageFile}'"
		done
	fi

	echo; echo "[$scriptName] Clean Workspace..."
	executeExpression "rm -rf propertiesForLocalTasks"
	if [ -d "TasksRemote" ]; then
		executeExpression "rm -rf TasksRemote"
	fi
	if [ -d "propertiesForRemoteTasks" ]; then
		executeExpression "rm -rf propertiesForRemoteTasks"
	fi
	if [ -d "propertiesForContainerTasks" ]; then
		executeExpression "rm -rf propertiesForContainerTasks"
	fi

	if [ -f "manifest.txt" ]; then
		executeExpression "rm -f manifest.txt"
	fi
	if [ -f "storeForLocal_manifest.txt" ]; then
		executeExpression "rm -f storeForLocal_manifest.txt"
	fi
	if [ -f "storeForRemote_manifest.txt" ]; then
		executeExpression "rm -f storeForRemote_manifest.txt"
	fi
	if [ -f "storeFor_manifest.txt" ]; then
		executeExpression "rm -f storeFor_manifest.txt"
	fi
fi

if [ -z $artifactPrefix ]; then
	echo "[$scriptName] Continuous Integration (CI) Finished, use ./TasksLocal/delivery.sh <env> to perform deployment."
else
	echo "[$scriptName] Continuous Integration (CI) Finished, use ./release.sh <env> to perform deployment."
fi
exit 0
