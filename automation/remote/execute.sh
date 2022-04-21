#!/usr/bin/env bash
set -e
scriptName=${0##*/}
export DEFAULT_IFS=$IFS

# This deploy script processes the package, and is therefore dependent on the build
# and package processes.

if [ -z "$1" ]; then
	echo "[$scriptName] Solution not passed. HALT!"
	exit 1
else
	SOLUTION=$1
fi

if [ -z "$2" ]; then
	echo "[$scriptName] Version not passed. HALT!"
	exit 2
else
	BUILDNUMBER=$2
fi

if [ -z "$3" ]; then
	echo "[$scriptName] Target not passed. HALT!"
	exit 3
else
	TARGET=$3
fi

if [ -z "$4" ]; then
	echo "[$scriptName] Execution Definition file (.tsk) not passed. HALT!"
	exit 4
else
	TASKLIST=$4
fi

# Consolidated Error processing function
#  required : error message
#  optional : exit code, if not supplied only error message is written
function ERRMSG {
	if [ -z "$2" ]; then
		echo; echo "[$scriptName][WARN]$1"
	else
		echo; echo "[$scriptName][ERROR]$1"
	fi
	if [ ! -z $CDAF_ERROR_DIAG ]; then
		echo; echo "[$scriptName] Invoke custom diag CDAF_ERROR_DIAG = $CDAF_ERROR_DIAG"; echo
		eval "$CDAF_ERROR_DIAG"
	fi
	if [ ! -z "$2" ]; then
		echo; echo "[$scriptName] Exit with LASTEXITCODE = $exitcode" ; echo
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

function MAKDIR {
	# Create Directory, if exists do nothing, else create
	#  required : directory name
	dirName="$1"
	executeFunction="mkdir -pv $dirName"
	echo "$executeFunction"
	eval "$executeFunction"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! ${executeFunction} returned $exitCode"
		exit $exitCode
	fi
}

# Delete (verbose)
function REMOVE {
	executeFunction="rm -rfv $1"
	echo "$executeFunction"
	set +f # enable globbing for remove operation
	eval "$executeFunction"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! ${executeFunction} returned $exitCode"
		exit $exitCode
	fi
}  

# Verbose Copy
function VECOPY {
	if [ -f $1 ] && [ -f $2 ]; then
		absFrom="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
		absTo="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
		if [ "$absFrom" == "$absTo" ]; then
			echo "From and to ($absFrom) are the same file, skipping..."
		fi
	else
		parentDir=$(dirname "$2")
		if [ ! -d "$parentDir" ]; then
			MAKDIR $parentDir
		fi
		executeFunction="cp -vR $1 $2"
		echo "$executeFunction"
		set +f # enable globbing for copy operation
		eval "$executeFunction"
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			ERRMSG "${executeFunction} returned $exitCode" $exitCode
		fi
	fi
}  

# Refresh Directory Contents
# If single argument clear directory, if two arguments, copy source to clean destination
function REFRSH {
	if [ -z $2 ]; then
		destination=$1
	else
		destination=$2
		source=$1
	fi
	MAKDIR "$destination"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! ${executeFunction} returned $exitCode"
		exit $exitCode
	fi
	REMOVE "$destination/*"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! ${executeFunction} returned $exitCode"
		exit $exitCode
	fi
	if [ ! -z $source ]; then
		if [ -d $source ]; then
			set +f # enable globbing for copy operation
			cp -vR --no-target-directory "$source" "$destination"
			if [ "$exitCode" != "0" ]; then
				echo "[$scriptName] Exception! ${executeFunction} returned $exitCode copying directory"
				exit $exitCode
			fi
		else
			VECOPY "$source" "$destination"
		fi
	fi
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! ${executeFunction} returned $exitCode"
		exit $exitCode
	fi
	if [ ! -z $source ]; then
		for fileName in $(find "$destination" -name "*.sh"); do 
			if [ ! -x "$fileName" ]; then
				echo " +x -> '$fileName'"
				chmod +x $fileName
			fi
		done
	fi
}  

# Decrypt a file
#  required : file to descrypt
#  optional : AES key, if not supplied will try SSH decrypt using $HOME/.ssl/private_key.pem
function DECRYP {
	./decryptKey.sh "$1" "$2"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! decryptKey.sh $1 $2 returned $exitCode"
		exit $exitCode
	fi
}  

# Detokenise a file
#  required : file to be detokenised
#  optional : properties file, by default the TARGET is used
#  optional : GPG key or variable expansion feature
function DETOKN {
	if [ -z "$1" ]; then
		echo "Token file not supplied!"; exit 3523
	fi
	if [ -z "$2" ]; then
		propertyFile=$TARGET
	else
		propertyFile=$2
	fi
	if [ ! -z "$3" ]; then
		if [[ "$3" == "resolve" || "$3" == "reveal" ]]; then
			export propldAction=$3
		else
			gpg=$3
		fi
	fi

	$AUTOMATIONHELPER/transform.sh "$propertyFile" "$1" "$gpg"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $AUTOMATIONHELPER/transform.sh \"$propertyFile\" \"$1\" \"$gpg\" returned $exitCode"
		exit $exitCode
	fi
	unset propldAction
}

# Replace in file
#  required : file, relative to current workspace
#  required : token, the token to be replaced
#  required : value, the replacement value
function REPLAC {
	fileName="$1"
	token="$2"
	value="$3"
	plaintext="$4"
	# Mac OSX sed 
	if [[ "$OSTYPE" == "darwin"* ]]; then
		executeFunction="sed -i '' -- \"s•${token}•${value}•g\" ${fileName}"
	else
		executeFunction="sed -i -- \"s•${token}•${value}•g\" ${fileName}"
	fi
	printable=$(echo "${executeFunction//•/â€¢}")
	if [ -z "$4" ]; then
		echo "${printable//${value}/*****}"
	else
		echo "${printable}"
	fi
	eval "$executeFunction"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! ${executeFunction} returned $exitCode"
		exit $exitCode
	fi
}

function IGNORE {
	# Execute command with only warning message if exit code is not zero
	#  required : command to execute
	set +e
	echo "$1"
	eval "$1"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][WARN] ${executeFunction} returned ${exitCode}, continuing ..."
	fi
	set -e
}

# Return MD5 as uppercase Hexadecimal
function MD5MSK {
	CURRENT_IFS=$IFS
	IFS=$DEFAULT_IFS
	read -ra array <<< $(echo -n $1 | md5sum)
	echo "${array[0]}" | tr '[:lower:]' '[:upper:]'
	IFS=$CURRENT_IFS
}

# Validate Variables (2.4.6)
function VARCHK {
	echo
	propertiesFile="$1"
	if [ ! -f "$propertiesFile" ]; then
		ERRMSG "[VARCHK_PROP_FILE_NOT_FOUND] $propertiesFile not found" 7781
	fi

	declare -i failureCount=0
	propList=$($AUTOMATIONHELPER/transform.sh "$propertiesFile")
	echo "$propList"; echo
	IFS=$'\n'
	for variableProp in $propList; do
		IFS='='
		read -ra array <<< "$variableProp"                        # Transform does not return $ prefix, but has two preceeding spaces
		variableValidation=$(eval "echo ${array[1]}")  
		variableName=$(echo "${array[0]}" | tr -d '[[:space:]]')  # trim preceeding spaces
		variableValue=$(eval "echo \$$variableName")
		if [ -z "$variableValidation" ]; then
			echo "  $variableName = '$variableValue'"
		elif [[ "$variableValidation" == 'optional' ]]; then
			if [ -z $variableValue ]; then
				echo "  $variableName = (optional secret not set)"
			else
			    echo "  $variableName = $(MD5MSK $variableValue) (MD5MSK optional secret)"
			fi
		elif [[ "$variableValidation" == 'required' ]]; then
			if [ -z $variableValue ]; then
				echo "  $variableName = [REQUIRED VARIABLE NOT SET]"
				failureCount=$((failureCount+1))
			else
			    echo "  $variableName = '$variableValue'"
			fi
		elif [[ "$variableValidation" == 'secret' ]]; then
			if [ -z $variableValue ]; then
				echo "  $variableName = [REQUIRED SECRET NOT SET]"
				failureCount=$((failureCount+1))
			else
			    echo "  $variableName = $(MD5MSK $variableValue) (MD5MSK required secret)"
			fi
		else
			validationEvaluated=$(eval "echo $variableValidation") # Resolve value containing a variable name, e.g. $variableValidation = '$SECRET_VALUE_MD5'
			variableValueMD5=$(MD5MSK $variableValue)
			if [[ "$variableValueMD5" == "$validationEvaluated" ]]; then
				echo "  $variableName = $variableValueMD5 (MD5MSK check success with '$variableValidation')"
			else
			    echo "  $variableName = $variableValueMD5 [MD5 CHECK FAILED FOR '$variableValidation']"
				failureCount=$((failureCount+1))
			fi
		fi
	done
	IFS=$DEFAULT_IFS
	if [ $failureCount -gt 0 ]; then
		ERRMSG "[VARCHK_FAILURE_COUNT] Validation Failures = $failureCount" $failureCount
	fi
}

# Expand argument for variables within properties
function resolveContent {
	eval "echo $1"
}

echo; echo "~~~~~~ Starting Execution Engine ~~~~~~~"; echo
echo "[$scriptName]   SOLUTION    : $SOLUTION"
echo "[$scriptName]   BUILDNUMBER : $BUILDNUMBER"
echo "[$scriptName]   TARGET      : $TARGET"
echo "[$scriptName]   TASKLIST    : $TASKLIST"
WORKSPACE=$(pwd)
echo "[$scriptName]   WORKSPACE   : $WORKSPACE"

if [ -z "$5" ]; then
	echo "[$scriptName]   OPT_ARG     : (not passed)"
else
	# case insensitive by forcing to uppercase
	testForClean=$(echo "$5" | tr '[a-z]' '[A-Z]')
	if [ "$testForClean" == "CLEAN" ]; then
		ACTION=$5
		echo "[$scriptName]   ACTION      : $ACTION"
	else
		OPT_ARG=$5
		echo "[$scriptName]   OPT_ARG     : $OPT_ARG"
	fi
fi

# Set the temporary directory (system wide)
TMPDIR=/tmp
echo "[$scriptName]   TMPDIR      : $TMPDIR"

# If this is a CI process, load temporary file as variables (implicit parameter passing) 
# this is not required in the PowerShell version as variables are global
if [ -f "../build.properties" ] ;then
	echo; echo "[$scriptName] Load ../build.properties"; echo
	eval $(cat ../build.properties)
	AUTOMATIONHELPER="$( cd "$(dirname "$0")" && pwd )"
	propertiesList=$($AUTOMATIONHELPER/transform.sh ../build.properties)
	printf "$propertiesList"
	eval $propertiesList
	echo; echo
	rm ../build.properties
else
	# If not build, is it a package process?
	if [ -f "./solution.properties" ] ;then
		echo; echo "[$scriptName] Load ./solution.properties"; echo
		eval $(cat ./solution.properties)
		AUTOMATIONHELPER="$( cd "$(dirname "$0")" && pwd )"
		propertiesList=$($AUTOMATIONHELPER/transform.sh ./solution.properties)
		printf "$propertiesList"
		eval $propertiesList
		echo
		rm ./solution.properties
	else
		# Neither build nor package, load target properties, i.e. it's either local or remote
		AUTOMATIONHELPER=.
		if [ -f "predeploy.properties" ]; then
			echo; echo "Load predeploy.properties ... "
			propertiesList=$($AUTOMATIONHELPER/transform.sh "predeploy.properties")
			printf "$propertiesList"
			eval $propertiesList
		else
			echo "[$scriptName]   predeploy   : (predeploy.properties not found, skipping)"
		fi
		echo
		echo "Load Target Properties ... $AUTOMATIONHELPER/transform.sh $TARGET"
		propertiesList=$($AUTOMATIONHELPER/transform.sh "$TARGET")
		printf "$propertiesList"
		eval $propertiesList
	fi
	echo; echo			
fi

# Process Task Execution
executionList=$(< $TASKLIST)
while read LINE; do
	if [[ $LINE == *"REMOVE"* ]] || [[ $LINE == *"REFRSH"* ]] || [[ $LINE == *"VECOPY"* ]]; then
		set -f # disable globbing, i.e. do not preprocess definitions containing wildcards
	fi
	# Execute the script, logging is left to the invoked script, unless an exception occurs
	EXECUTABLESCRIPT=$(echo $LINE | cut -d '#' -f 1)
	
	# Check for cross platform key words, first 6 characters, by convention uppercase but either supported
	read -ra exprArray <<< ${LINE}
	feature=$(echo "${exprArray[0]}" | tr '[a-z]' '[A-Z]')
	arguments=$(echo "${exprArray[@]:1}")

	# Exit argument set
	if [ "$feature" == "EXITIF" ]; then
		IFS=' ' read -ra ADDR <<< $LINE
		exitVar="${ADDR[1]}"
		condition="${ADDR[2]}"
		echo $exitVar
		echo $condition
		
		if [ -z "$condition" ]; then
			printf "$LINE ==> if [ ${exitVar} ]; then exit"
			EXECUTABLESCRIPT="if [ ${exitVar} ]; then "
			EXECUTABLESCRIPT+="echo \". Controlled exit due to \$exitVar being set\";exit;fi"
		else
			printf "$LINE ==> if [[ ${exitVar} == '$condition' ]]; then exit"
			EXECUTABLESCRIPT="if [[ ${exitVar} == '$condition' ]]; then "
			EXECUTABLESCRIPT+="echo \". Controlled exit due to $exitVar = $condition\";exit;fi"
		fi
	fi

	# Exit argument set
	if [ "$feature" == "PROPLD" ]; then
		propFile="${exprArray[1]}"
		propldAction="${exprArray[2]}"
		execute="$AUTOMATIONHELPER/transform.sh $propFile"
		propertiesList=$(eval $execute)
		if [[ "$propldAction" == "resolve" || "$propldAction" == "reveal" ]]; then
			echo "PROPLD $propldAction variables defined within $propFile"; echo
			revealed=()
			for nameContent in $propertiesList; do
				echo "  $nameContent"
				IFS='=' read -r name content <<< "$nameContent"
				IFS=$DEFAULT_IFS
				resolved=$(eval resolveContent $content)
				revealed+=("  $name = '$resolved'")
				eval "$name='$resolved'"
			done
			if [[ "$propldAction" == "reveal" ]]; then
				echo; printf '%s\n' "${revealed[@]}"
			fi
		else
			echo "PROPLD variables defined within $propFile"; echo
			for nameContent in $propertiesList; do
				echo "  $nameContent"
			done
			eval $propertiesList
		fi
	fi

	# Set a variable, PowerShell format, start as position 8 to strip the $ for Linux
	if [ "$feature" == "ASSIGN" ]; then
		printf "$LINE ==> "
		IFS='=' read -r name value <<< "$arguments"
		IFS=$DEFAULT_IFS
		EXECUTABLESCRIPT="$(echo "${name}" | xargs | sed 's/\$//g')='$(eval "resolveContent $value")'"
	fi

	# Invoke a custom script
	if [ "$feature" == "INVOKE" ]; then
		printf "$LINE ==> "
		scriptLine="${arguments}"
		sep=' '
		
		case $scriptLine in
		(*"$sep"*)
			script=${scriptLine%%"$sep"*}
    	    arguments=${scriptLine#*"$sep"}
    	    EXECUTABLESCRIPT="$script"
    	    EXECUTABLESCRIPT+=".sh $arguments"
    	    ;;
		(*)
    	    EXECUTABLESCRIPT="$scriptLine"
    	    EXECUTABLESCRIPT+=".sh"
		    ;;
		esac
	fi

	# Execute Remote Command or Local Shell Script (via ssh)
	if [ "$feature" == "EXCREM" ]; then
		printf "$LINE ==> "
		scriptLine="${arguments}"
		sep=' '
   	    EXECUTABLESCRIPT='./remoteExec.sh'
		case $scriptLine in
		(*"$sep"*)
			command=${scriptLine%%"$sep"*}
    	    arguments=${scriptLine#*"$sep"}
    	    EXECUTABLESCRIPT+=" $deployHost $deployUser $command $arguments"
    	    ;;
		(*)
    	    EXECUTABLESCRIPT+=" $deployHost $deployUser $scriptLine"
		    ;;
		esac
	fi

	# Compress to file
	#  required : file, relative to current workspace
	#  required : source directory, relative to current workspace
	if [ "$feature" == "CMPRSS" ]; then
		printf "$LINE ==> "
		stringarray=($LINE)
		fileName=${stringarray[1]}
		if [ -z ${stringarray[2]} ]; then
			sourceDir=${stringarray[1]}
		else
			sourceDir=${stringarray[2]}
		fi
		EXECUTABLESCRIPT="tar -zcvf ${fileName}.tar.gz --exclude=\"*.git\" --exclude=\"*.svn\" ${sourceDir}"
	fi

	# Decommpress from file
	#  required : file, relative to current workspace
	if [ "$feature" == "DCMPRS" ]; then
		printf "$LINE ==> "
		stringarray=($LINE)
		fileName=${stringarray[1]}
		targetDir=${stringarray[2]}
		if [ -z "$targetDir" ]; then
			EXECUTABLESCRIPT="tar -zxvf ./${fileName}.tar.gz"
		else
			EXECUTABLESCRIPT="tar -zxvf ./${fileName}.tar.gz --directory ${targetDir}"
		fi
	fi

	# Perform no further processing if Feature is Property Loader
	if [ "$feature" != "PROPLD" ]; then
		if [ ! -z "$EXECUTABLESCRIPT" ]; then
			# Do not echo line if it is an echo itself or it is determining controlled exit
			if [ "${LINE:0:4}" != "echo" ] && [ "$feature" != "EXITIF" ]; then
# This leaks secrets, but I have left it should someone need to temporarily use it for debugging					
#				echo $(eval echo "$EXECUTABLESCRIPT")
				echo "$EXECUTABLESCRIPT"
			fi
		else
			# Do not add whitespace line feed when script has a comment
			if [ "${LINE:0:1}" != "#" ]; then
				EXECUTABLESCRIPT="echo"
			fi
		fi
		eval $EXECUTABLESCRIPT
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
			exit $exitCode
		fi
	fi
	
done < <(echo "$executionList")

echo; echo "~~~~~~ Shutdown Execution Engine ~~~~~~"
