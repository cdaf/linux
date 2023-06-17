#!/usr/bin/env bash


# Consolidated Error processing function
#  required : error message
#  optional : exit code, if not supplied only error message is written
function ERRMSG {
	if [ -z "$2" ]; then
		echo; echo "[$scriptName][ERRMSG][WARN] $1"
	else
		echo; echo "[$scriptName][ERRMSG][ERROR] $1"
	fi
	if [ ! -z "$CDAF_ERROR_DIAG" ]; then
		echo "[$scriptName][ERRMSG]   Invoke custom diag CDAF_ERROR_DIAG = '$CDAF_ERROR_DIAG'"; echo
		eval "$CDAF_ERROR_DIAG"
	fi
	if [ ! -z "$2" ]; then
		echo; echo "[$scriptName][ERRMSG] Exit with LASTEXITCODE = $2" ; echo
		exit $2
	fi
}

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		ERRMSG "$EXECUTABLESCRIPT returned $exitCode" $exitCode
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

function executeIgnore {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][WARN] $EXECUTABLESCRIPT returned $exitCode"
	fi
}

# Entry point for building projects and packaging solution. 
scriptName='buildPackage.sh'

# Processed out of order as needed for solution determination
export AUTOMATIONROOT="$(dirname $( cd "$(dirname "$0")" && pwd ))"
export CDAF_CORE="${AUTOMATIONROOT}/remote"

BUILDNUMBER="$1"
if [ -z $BUILDNUMBER ]; then
	# Use a simple text file (${HOME}/buildnumber.counter) for incremental build number
	if [ -f "${HOME}/buildnumber.counter" ]; then
		let "BUILDNUMBER=$(cat ${HOME}/buildnumber.counter)"
	else
		let "BUILDNUMBER=0"
	fi
	if [ "$caseinsensitive" != "cdonly" ]; then
		let "BUILDNUMBER=$BUILDNUMBER + 1"
	fi
	echo $BUILDNUMBER > ${HOME}/buildnumber.counter
	echo "[$scriptName]   BUILDNUMBER     : $BUILDNUMBER (not passed, using local counterfile ${HOME}/buildnumber.counter)"
else
	BUILDNUMBER=$(eval echo $BUILDNUMBER)
	echo "[$scriptName]   BUILDNUMBER     : $BUILDNUMBER"
fi

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
export REVISION="$REVISION"

ACTION="$3"
echo "[$scriptName]   ACTION          : $ACTION"
caseinsensitive=$(echo "$ACTION" | tr '[A-Z]' '[a-z]')

LOCAL_WORK_DIR="$4"
if [ -z $LOCAL_WORK_DIR ]; then
	LOCAL_WORK_DIR='TasksLocal'
	echo "[$scriptName]   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR (default)"
else
	echo "[$scriptName]   LOCAL_WORK_DIR  : $LOCAL_WORK_DIR"
fi

REMOTE_WORK_DIR="$5"
if [ -z $REMOTE_WORK_DIR ]; then
	REMOTE_WORK_DIR='TasksRemote'
	echo "[$scriptName]   REMOTE_WORK_DIR : $REMOTE_WORK_DIR (default)"
else
	echo "[$scriptName]   REMOTE_WORK_DIR : $REMOTE_WORK_DIR"
fi

# Use passed argument to determine if a value was passed or if a default was set and used above
echo "[$scriptName]   AUTOMATIONROOT  : $AUTOMATIONROOT"

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
for i in $(find . -mindepth 1 -maxdepth 1 -type d); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ]; then
		export SOLUTIONROOT="$directoryName"
	fi
done
if [ -z "$SOLUTIONROOT" ]; then
	SOLUTIONROOT="$AUTOMATIONROOT/solution"
	solutionMessage="(default, project directory containing CDAF.solution not found)"
else
	if [[ $SOLUTION == *'$'* ]]; then
		SOLUTIONROOT=$(eval echo $SOLUTIONROOT)
		solutionMessage="(found and evaluated from CDAF.solution)"
	else
		solutionMessage="(found CDAF.solution)"
	fi
fi
export SOLUTIONROOT="$( cd "$SOLUTIONROOT" && pwd )"
echo "[$scriptName]   SOLUTIONROOT    : $SOLUTIONROOT $solutionMessage"

export SOLUTION=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "solutionName")
exitCode=$?
if [ "$exitCode" != "0" ]; then
	ERRMSG "[SOLUTION_NOT_FOUND] Read of SOLUTION from $SOLUTIONROOT/CDAF.solution failed!" $exitCode
fi
if [ -z "$SOLUTION" ]; then
	ERRMSG "[SOLUTION_NAME_NOT_SET] solutionName not found in $SOLUTIONROOT/CDAF.solution!" 1030
fi
echo "[$scriptName]   SOLUTION        : $SOLUTION (from CDAF.solution)"

export WORKSPACE="$(pwd)"
echo "[$scriptName]   pwd             : ${WORKSPACE}"
echo "[$scriptName]   hostname        : $(hostname)"
echo "[$scriptName]   whoami          : $(whoami)"

echo "[$scriptName]   CDAF Version    : $(${CDAF_CORE}/getProperty.sh "$AUTOMATIONROOT/CDAF.linux" "productVersion")"

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

#---------------------------------------------------------------------
# Configuration Management transformation only if not within container
#---------------------------------------------------------------------
if [[ "$ACTION" != 'container_build' ]]; then

	# Properties generator (added in release 1.7.8, extended to list in 1.8.11, moved from build to pre-process 1.8.14), added container tasks 2.4.0
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

	echo; echo "[$scriptName] Remove Build Process Temporary files and directories"; echo # perform explicit removal as rm -rfv is too verbose
	for packageArtefact in $(echo "manifest.txt ./propertiesForRemoteTasks ./propertiesForLocalTasks ./propertiesForContainerTasks"); do
		if [ -d  "${packageArtefact}" ]; then
			echo "  removed ${packageArtefact}"
			rm -rf ${packageArtefact}
		else
			if [ -f  "${packageArtefact}" ]; then
				echo "  removed ${packageArtefact}"
				rm -f ${packageArtefact}
			fi
		fi
	done

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
fi

#--------------------------------------------------------------------------
# 2.6.2 Only log system variables if set
#--------------------------------------------------------------------------
loggingList=()

# 2.5.5 default error diagnostic command as solution property
if [ -z "$CDAF_ERROR_DIAG" ]; then
	export CDAF_ERROR_DIAG=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "CDAF_ERROR_DIAG")
	if [ ! -z "$CDAF_ERROR_DIAG" ]; then
		loggingList+=("[$scriptName]   CDAF_ERROR_DIAG     : $CDAF_ERROR_DIAG (defined in $SOLUTIONROOT/CDAF.solution)")
	fi
else
	loggingList+=("[$scriptName]   CDAF_ERROR_DIAG     : $CDAF_ERROR_DIAG")
fi

if [ -z "$CDAF_IGNORE_WARNING" ]; then
	export CDAF_IGNORE_WARNING=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "CDAF_IGNORE_WARNING")
	if [ ! -z "$CDAF_IGNORE_WARNING" ]; then
		loggingList+=("[$scriptName]   CDAF_IGNORE_WARNING : $CDAF_IGNORE_WARNING (defined in $SOLUTIONROOT/CDAF.solution)")
	fi
else
	loggingList+=("[$scriptName]   CDAF_IGNORE_WARNING : $CDAF_IGNORE_WARNING")
fi

if [ -z "$CDAF_OVERRIDE_TOKEN" ]; then
	export CDAF_OVERRIDE_TOKEN=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "CDAF_OVERRIDE_TOKEN")
	if [ ! -z "$CDAF_OVERRIDE_TOKEN" ]; then
		loggingList+=("[$scriptName]   CDAF_OVERRIDE_TOKEN : $CDAF_OVERRIDE_TOKEN (defined in $SOLUTIONROOT/CDAF.solution)")
	fi
else
	loggingList+=("[$scriptName]   CDAF_OVERRIDE_TOKEN : $CDAF_OVERRIDE_TOKEN")
fi

if [ ! -z "$loggingList" ];then
	echo; echo "[$scriptName] CDAF System Variables Set ..."
	for ((i = 0; i < ${#loggingList[@]}; ++i)); do echo "${loggingList[$i]}"; done
fi

#--------------------------------------------------------------------------
# Do not load and log containerBuild properties when executing in container
#--------------------------------------------------------------------------
if [[ "$ACTION" == 'container_build' ]]; then

	echo ; echo "[$scriptName] ACTION = $ACTION, Executing build in container..."

else

	#--------------------------------------------------------------------------
	# 2.6.2 Only log container properties if set
	#--------------------------------------------------------------------------
	loggingList=()

	if [ -z "$CDAF_SKIP_CONTAINER_BUILD" ]; then
		export CDAF_SKIP_CONTAINER_BUILD=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "CDAF_SKIP_CONTAINER_BUILD")
		if [ ! -z "$CDAF_SKIP_CONTAINER_BUILD" ]; then
			loggingList+=("[$scriptName]   CDAF_SKIP_CONTAINER_BUILD : $CDAF_SKIP_CONTAINER_BUILD (defined in $SOLUTIONROOT/CDAF.solution)")
		fi
	else
		loggingList+=("[$scriptName]   CDAF_SKIP_CONTAINER_BUILD : $CDAF_SKIP_CONTAINER_BUILD")
	fi

	if [ -z "$CDAF_DOCKER_REQUIRED" ]; then
		export CDAF_DOCKER_REQUIRED=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "CDAF_DOCKER_REQUIRED")
		if [ ! -z "$CDAF_DOCKER_REQUIRED" ]; then
			loggingList+=("[$scriptName]   CDAF_DOCKER_REQUIRED      : $CDAF_DOCKER_REQUIRED (defined in $SOLUTIONROOT/CDAF.solution)")
		fi
	else
		loggingList+=("[$scriptName]   CDAF_DOCKER_REQUIRED      : $CDAF_DOCKER_REQUIRED")
	fi

	# 1.6.7 Do not load and log incompatible properties for Container Build process
	containerBuild=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "containerBuild")

	# Support for image as an environment variable, do not overwrite if already set
	containerImage=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "containerImage")
	if [ ! -z "$containerImage" ]; then
		if [ -z $CONTAINER_IMAGE ]; then
			export CONTAINER_IMAGE="$containerImage"
			loggingList+=("[$scriptName]   CONTAINER_IMAGE           : $CONTAINER_IMAGE (set to \$containerImage)")
		else
			loggingList+=("[$scriptName]   containerImage            : $containerImage")
			loggingList+=("[$scriptName]   CONTAINER_IMAGE           : $CONTAINER_IMAGE (not changed as already set)")
		fi

		# 2.6.1 default containerBuild process
		if [ -z "$containerBuild" ]; then
			containerBuild='"$AUTOMATIONROOT/processor/containerBuild.sh" "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$ACTION"'
			defaultCBProcess='(default) '
		fi
	fi

	if [ ! -z "$containerBuild" ]; then
		loggingList+=("[$scriptName]   containerBuild            : $containerBuild $defaultCBProcess")
	fi

	# 2.2.0 Image Build as incorperated function
	buildImage=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "buildImage")
	imageBuild=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "imageBuild")
	if [ ! -z "$buildImage" ]; then
		loggingList+=("[$scriptName]   buildImage                : $buildImage")
		# 2.6.1 imageBuild mimimum configuration, with default process
		if [ -z "$imageBuild" ]; then
			imageBuild='"${CDAF_CORE}/imageBuild.sh" "${SOLUTION}_${REVISION}" "${BUILDNUMBER}" "${buildImage}" "${LOCAL_WORK_DIR}"'
			defaultIBProcess='(default) '
		fi
	fi

	if [ ! -z "$imageBuild" ]; then
		loggingList+=("[$scriptName]   imageBuild                : $imageBuild $defaultIBProcess")
	fi

	#---------------------------------------------------------------------
	# Properties Loaded, perform container execution validation steps
	#---------------------------------------------------------------------
	if [ ! -z "$containerBuild" ] || [ ! -z "$imageBuild" ]; then
		# 2.5.5 support conditional containerBuild based on environment variable
		if [ ! -z $CDAF_SKIP_CONTAINER_BUILD ] || [[ "$ACTION" == 'skip_container_build' ]]; then
			loggingList+=("[$scriptName] \$ACTION = $ACTION, container build defined (${containerBuild}) but skipped ...")
			unset containerBuild
			unset imageBuild
		else
			test=$(docker --version 2>&1)
			if [ $? -ne 0 ]; then
				if [ ! -z $CDAF_DOCKER_REQUIRED ]; then
					echo ; echo "[$scriptName] CDAF Container Features Set ..."
					for ((i = 0; i < ${#loggingList[@]}; ++i)); do echo "${loggingList[$i]}"; done
					ERRMSG "[DOCKER_NOT_INSTALLED] Docker service not installed, but CDAF_DOCKER_REQUIRED = ${CDAF_DOCKER_REQUIRED}, so halting!" 8911
				else
					loggingList+=("[$scriptName]   Docker                    : containerBuild defined in $SOLUTIONROOT/CDAF.solution, but Docker not installed, will attempt to execute natively")
					unset containerBuild
					unset imageBuild
				fi
			else
				IFS=' ' read -ra ADDR <<< $test
				IFS=',' read -ra ADDR <<< ${ADDR[2]}
				loggingList+=("[$scriptName]   Docker                    : ${ADDR[0]}")
				# Test Docker is running
				test=$(docker images 2>&1)
				if [ "$?" != "0" ]; then
					loggingList+=("[$scriptName] Docker installed but not running, CDAF_DOCKER_REQUIRED is set so will try and start")
					if [ $(whoami) != 'root' ];then
						elevate='sudo'
					fi
					executeExpression "$elevate service docker start"
					executeExpression "$elevate service docker status"
					docker images
					exitCode=$?
					if [ $exitCode -eq 0 ]; then
						loggingList+=("[$scriptName]   Docker                    : ${ADDR[0]}")
					else
						if [ ! -z $CDAF_DOCKER_REQUIRED ]; then
							echo ; echo "[$scriptName] CDAF Container Features Set ..."
							for ((i = 0; i < ${#loggingList[@]}; ++i)); do echo "${loggingList[$i]}"; done
							ERRMSG "[DOCKER_NOT_STARTING] Docker service not installed but cannot be started, CDAF_DOCKER_REQUIRED = ${CDAF_DOCKER_REQUIRED}, so halting!" 8912
						else
							loggingList+=("[$scriptName]   Docker                    : ${ADDR[0]} (Docker service not installed but cannot be started, will attempt to run natively)")
							unset containerBuild
							unset imageBuild
						fi
					fi
				fi
			fi
		fi
	fi

	if [ ! -z "$loggingList" ];then
		echo; echo "[$scriptName] CDAF Container Features Set ..."
		for ((i = 0; i < ${#loggingList[@]}; ++i)); do echo "${loggingList[$i]}"; done
	fi
fi

#--------------------------------------------------------------------------
# Start build process
#--------------------------------------------------------------------------

# 2.4.4 Pre-Build Tasks, exclude from container_build to avoid performing twice
if [ -f $prebuildTasks ] && [ "$ACTION" != 'container_build' ]; then
	# Set properties for execution engine

	echo; echo "Process Pre-Build Tasks ..."
	${CDAF_CORE}/execute.sh "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$prebuildTasks" "$ACTION" 2>&1
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		ERRMSG "[PREBUILD_FAILURE] Linear deployment activity (${CDAF_CORE}/execute.sh $SOLUTION $BUILDNUMBER package $SOLUTIONROOT/package.tsk) failed! Returned $exitCode" $exitCode
	fi
fi

# CDAF 1.7.0 Container Build process
if [ ! -z "$containerBuild" ] && [ "$caseinsensitive" != "clean" ] && [ "$caseinsensitive" != "packageonly" ]; then
	echo; echo "[$scriptName] Execute container build ${defaultCBProcess}..."; echo
	executeExpression "$containerBuild"
else
	if [ "$caseinsensitive" == "packageonly" ]; then
		echo; echo "[$scriptName] action is ${ACTION}, do not perform build."
	else
		$AUTOMATIONROOT/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$ACTION"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			ERRMSG "[BUILD_PROJECT] Project(s) Build Failed! $AUTOMATIONROOT/buildandpackage/buildProjects.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$ACTION\"." $exitCode
		fi
	fi

	# 2.4.4 Process optional post build, pre-packaging tasks
	if [ -f $postbuild ]; then

		echo; echo "Process Post-Build Tasks ..."
		${CDAF_CORE}/execute.sh "$SOLUTION" "$BUILDNUMBER" "$SOLUTIONROOT" "$postbuild" "$ACTION" 2>&1
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			ERRMSG "[POSTBUILD_FAIL] Linear deployment activity (${CDAF_CORE}/execute.sh $SOLUTION $BUILDNUMBER package $SOLUTIONROOT/package.tsk) failed! Returned $exitCode" $exitCode
		fi
	fi

	# 2.6.1 Process optional post build, pre-packaging process
	postBuild=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "postBuild")
	if [ ! -z "$postBuild" ]; then
		executeExpression "$postBuild"
	fi
	
	if [ "$caseinsensitive" == "buildonly" ]; then
		echo "[$scriptName] action is ${ACTION}, do not perform package."
	else
		$AUTOMATIONROOT/buildandpackage/package.sh "$SOLUTION" "$BUILDNUMBER" "$REVISION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR" "$ACTION"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			ERRMSG "[PACKAGE_FAIL] Solution Package Failed! $AUTOMATIONROOT/buildandpackage/package.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$REVISION\" \"$LOCAL_WORK_DIR\" \"$REMOTE_WORK_DIR\" \"$ACTION\"." $exitCode
		fi
	fi
fi

#-------------------------------------------------------
# Build process complete, start image and file packaging
#-------------------------------------------------------

if [ "$ACTION" != 'container_build' ]; then

	# 2.2.0 Image Build as incorperated function, no longer conditional on containerBuild, but do not attempt if within containerbuild
	if [ ! -z "$imageBuild" ]; then
		echo; echo "[$scriptName] Execute image build ${defaultIBProcess}..."
		test=$(docker --version 2>&1)
		if [[ $? -ne 0 ]]; then
			echo "[$scriptName] imageBuild defined in $SOLUTIONROOT/CDAF.solution, but Docker not installed, skipping ..."
		else
			if [ -z "$buildImage" ]; then
				# If an explicit image is not defined, perform implicit cascading load
				runtimeImage=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "runtimeImage")
				if [ ! -z "$runtimeImage" ]; then
					echo "[$scriptName]   runtimeImage  = $runtimeImage"
				else
					runtimeImage=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "containerImage")
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
			fi

			constructor=$("${CDAF_CORE}/getProperty.sh" "$SOLUTIONROOT/CDAF.solution" "constructor")
			if [ ! -z "$constructor" ]; then
				echo "[$scriptName]   constructor   = $constructor"
			fi
			executeExpression "$imageBuild"
		fi
	fi

	# CDAF 2.1.0 Self-extracting Script Artifact
	artifactPrefix=$(${CDAF_CORE}/getProperty.sh "$SOLUTIONROOT/CDAF.solution" "artifactPrefix")
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

	echo; echo "[$scriptName] Clean Workspace..."
	# CDAF 2.1.0 Self-extracting Script Artifact
	if [ ! -z $artifactPrefix ]; then
		executeIgnore "rm -rf TasksLocal"
		executeIgnore "rm -rf propertiesForLocalTasks"
		for packageFile in $(find . -maxdepth 1 -type f -name "${SOLUTION}-*.gz"); do
			executeIgnore "rm '${packageFile}'"
		done
	fi

	executeIgnore "rm -rf propertiesForLocalTasks"
	if [ -d "TasksRemote" ]; then
		executeIgnore "rm -rf TasksRemote"
	fi
	if [ -d "propertiesForRemoteTasks" ]; then
		executeIgnore "rm -rf propertiesForRemoteTasks"
	fi
	if [ -d "propertiesForContainerTasks" ]; then
		executeIgnore "rm -rf propertiesForContainerTasks"
	fi

	if [ -f "manifest.txt" ]; then
		executeIgnore "rm -f manifest.txt"
	fi
	if [ -f "storeForLocal_manifest.txt" ]; then
		executeIgnore "rm -f storeForLocal_manifest.txt"
	fi
	if [ -f "storeForRemote_manifest.txt" ]; then
		executeIgnore "rm -f storeForRemote_manifest.txt"
	fi
	if [ -f "storeFor_manifest.txt" ]; then
		executeIgnore "rm -f storeFor_manifest.txt"
	fi
fi

echo
if [ -z $artifactPrefix ]; then
	echo "[$scriptName] Continuous Integration (CI) Finished, use ./TasksLocal/delivery.sh <env> to perform deployment."
else
	echo "[$scriptName] Continuous Integration (CI) Finished, use ./release.sh <env> to perform deployment."
fi
exit 0
