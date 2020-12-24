#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# This deploy script processes the package, and is therefore dependant on the build
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

# Delete (verbose)
function VECOPY {
	executeFunction="cp -vR $1 $2"
	echo "$executeFunction"
	set +f # enable globbing for copy operation
	eval "$executeFunction"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! ${executeFunction} returned $exitCode"
		exit $exitCode
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
#  optional : AES key
function DETOKN {
	if [ -z "$1" ]; then
		echo "Token file not supplied!"; exit 3523
	fi
	if [ -z "$2" ]; then
		propertyFile=$TARGET
	else
		propertyFile=$2
	fi
	./transform.sh "$propertyFile" "$1" "$3"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! ./transform.sh \"$propertyFile\" \"$1\" \"$3\" returned $exitCode"
		exit $exitCode
	fi
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
	echo "$1"
	eval "$1"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][WARN] ${executeFunction} returned ${exitCode}, continuing ..."
	fi
}

echo; echo "~~~~~~ Starting Execution Engine ~~~~~~~"; echo
echo "[$scriptName]   SOLUTION    : $SOLUTION"
echo "[$scriptName]   BUILDNUMBER : $BUILDNUMBER"
echo "[$scriptName]   TARGET      : $TARGET"
echo "[$scriptName]   TASKLIST    : $TASKLIST"

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
	AUTOMATIONHELPER="$( cd "$(dirname "$0")" ; pwd -P )"
	propertiesList=$($AUTOMATIONHELPER/transform.sh ../build.properties)
	printf "$propertiesList"
	eval $propertiesList
	echo
	rm ../build.properties
else
	# If not build, is it a package process?
	if [ -f "./solution.properties" ] ;then
		echo; echo "[$scriptName] Load ./solution.properties"; echo
		eval $(cat ./solution.properties)
		AUTOMATIONHELPER="$( cd "$(dirname "$0")" ; pwd -P )"
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
		echo "Load Target Properties ... "
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
	feature=$(echo "${LINE:0:6}" | tr '[a-z]' '[A-Z]')

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
		propFile="${LINE:7}"
		echo "$LINE ==> $AUTOMATIONHELPER/transform.sh $propFile"
		echo
		execute="$AUTOMATIONHELPER/transform.sh $propFile"
		propertiesList=$(eval $execute)
		printf "$propertiesList"
		eval $propertiesList
		echo			
		loadProperties=""
	fi

	# Set a variable, PowerShell format, start as position 8 to strip the $ for Linux
	if [ "$feature" == "ASSIGN" ]; then
		printf "$LINE ==> "
		EXECUTABLESCRIPT="${LINE:8}"
	fi

	# Invoke a custom script
	if [ "$feature" == "INVOKE" ]; then
		printf "$LINE ==> "
		scriptLine="${LINE:7}"
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
		scriptLine="${LINE:7}"
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
		sourceDir=${stringarray[2]}
		if [ "$sourceDir" == '.' ]; then
			EXECUTABLESCRIPT="tar -zcv --exclude=\"*.git\" --exclude=\"*.svn\" -f ${fileName}.tar.gz ."
		else
			sourcePath=$(dirname $(readlink -f ${sourceDir}))
			sourceName=$(basename ${sourceDir})
			EXECUTABLESCRIPT="tar -zcv --exclude=\"*.git\" --exclude=\"*.svn\" -C ${sourceDir} -f ${fileName}.tar.gz"
		fi
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
# This leaks secrets, but I have left it should someone need to temporarilty use it for debugging					
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
