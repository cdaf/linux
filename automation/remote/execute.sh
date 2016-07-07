#!/usr/bin/env bash
set -e

# This deploy script processes the package, and is therefore dependant on the build
# and package processes.

if [ -z "$1" ]; then
	echo "$0 : Solution not passed. HALT!"
	exit 1
else
	SOLUTION=$1
fi

if [ -z "$2" ]; then
	echo "$0 : Version not passed. HALT!"
	exit 2
else
	BUILDNUMBER=$2
fi

if [ -z "$3" ]; then
	echo "$0 : Target not passed. HALT!"
	exit 3
else
	TARGET=$3
fi

if [ -z "$4" ]; then
	echo "$0 : Execution Definition file (.tsk) not passed. HALT!"
	exit 4
else
	TASKLIST=$4
fi

echo
echo "~~~~~~ Starting Execution Engine ~~~~~~~"
echo
echo "$0 :   SOLUTION    : $SOLUTION"
echo "$0 :   BUILDNUMBER : $BUILDNUMBER"
echo "$0 :   TARGET      : $TARGET"
echo "$0 :   TASKLIST    : $TASKLIST"

if [ -z "$5" ]; then
	echo "$0 :   OPT_ARG     : (not passed)"
else
	# case insensitive by forcing to uppercase
	testForClean=$(echo "$5" | tr '[a-z]' '[A-Z]')
	if [ "$testForClean" == "CLEAN" ]; then
		ACTION=$5
		echo "$0 :   ACTION      : $ACTION"
	else
		OPT_ARG=$5
		echo "$0 :   OPT_ARG     : $OPT_ARG"
	fi
fi

# Set the temporary directory (system wide)
TMPDIR=/tmp
echo "$0 :   TMPDIR      : $TMPDIR"

# If this is a CI process, load temporary file as variables (implicit parameter passing) 
# this is not required in the PowerShell version as variables are global
AUTOMATIONHELPER=.
if [ -f "../build.properties" ] ;then
	echo
	echo "$0 : Load ../build.properties"
	echo
	eval $(cat ../build.properties)
	AUTOMATIONHELPER="../$AUTOMATIONROOT/remote"
	propertiesList=$($AUTOMATIONHELPER/transform.sh ../build.properties)
	printf "$propertiesList"
	eval $propertiesList
	rm ../build.properties
	echo
else
	# If not build, is it a package process?
	if [ -f "./package.properties" ] ;then
		echo
		echo "$0 : Load ./package.properties"
		echo
		eval $(cat ./package.properties)
		AUTOMATIONHELPER="./$AUTOMATIONROOT/remote"
		propertiesList=$($AUTOMATIONHELPER/transform.sh ./package.properties)
		printf "$propertiesList"
		eval $propertiesList
		rm ./package.properties
	else
		# Neither build nor package, load target properties, i.e. it's either local or remote
		echo
		echo "Load Target Properties ... "
		propertiesList=$($AUTOMATIONHELPER/transform.sh "$TARGET")
		printf "$propertiesList"
		eval $propertiesList
		echo
		echo			
	fi
fi

# Process Task Execution
while read LINE
do
	# Execute the script, logging is left to the invoked script, unless an exception occurs
	EXECUTABLESCRIPT=$(echo $LINE | cut -d '#' -f 1)
	
	# Check for cross platform key words, first 6 characters, by convention uppercase but either supported
	feature=$(echo "${LINE:0:6}" | tr '[a-z]' '[A-Z]')

	# Exit argument set
	if [ "$feature" == "EXITIF" ]; then
		exitVar="${LINE:7}"
		printf "$LINE ==> if [ $exitVar ] then exit"
		EXECUTABLESCRIPT="if [ $exitVar ]; then "
		EXECUTABLESCRIPT+="echo \"Controlled exit due to \$exitVar = $exitVar\";exit;fi"
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

	# Create Directory (verbose)
	if [ "$feature" == "MAKDIR" ]; then
		printf "$LINE ==> "
		EXECUTABLESCRIPT="mkdir -pv ${LINE:7}"
	fi

	# Delete (verbose)
	if [ "$feature" == "REMOVE" ]; then
		printf "$LINE ==> "
		EXECUTABLESCRIPT="rm -rfv ${LINE:7}"
	fi

	# Copy (verbose)
	if [ "$feature" == "VECOPY" ]; then
		printf "$LINE ==> "
		EXECUTABLESCRIPT="cp -vR ${LINE:7}"
	fi

	# Decrypt a file
	#  required : directory, file location relative to current workspace
	#  optional : file, is not will try file with the same name as target in the directory
	if [ "$feature" == "DECRYP" ]; then
		printf "$LINE ==> "
		EXECUTABLESCRIPT='RESULT=$(./decryptKey.sh $TARGET '
		EXECUTABLESCRIPT+="${LINE:7})"
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

	# Detokenise a file
	#  required : file to be detokenised
	#  optional : properties file, by default the TARGET is used
	if [ "$feature" == "DETOKN" ]; then
		printf "$LINE ==> "
		scriptLine="${LINE:7}"
		sep=' '
		
		case $scriptLine in
		(*"$sep"*)
			tokenFile=${scriptLine%%"$sep"*}
    	    properties=${scriptLine#*"$sep"}
    	    EXECUTABLESCRIPT='./transform.sh '
    	    EXECUTABLESCRIPT+="$properties $tokenFile"
    	    ;;
		(*)
    	    EXECUTABLESCRIPT='./transform.sh '
    	    EXECUTABLESCRIPT+="$TARGET $scriptLine"
			;;
		esac
	fi

	# Replace in file
	#  required : file, relative to current workspace
	#  required : name, the token to be replaced
	#  required : value, the replacement value
	if [ "$feature" == "REPLAC" ]; then
		printf "$LINE ==> "
		stringarray=($LINE)
		fileName=${stringarray[1]}
		name=${stringarray[2]}
		value=${stringarray[3]}
		# Mac OSX sed 
		if [[ "$OSTYPE" == "darwin"* ]]; then
			EXECUTABLESCRIPT="sed -i '' -- \"s/${name}/${value}/g\" ${fileName}"
		else
			EXECUTABLESCRIPT="sed -i -- \"s/${name}/${value}/g\" ${fileName}"
		fi
	fi

	# Compress to file
	#  required : file, relative to current workspace
	#  required : source directory, relative to current workspace
	if [ "$feature" == "CMPRSS" ]; then
		printf "$LINE ==> "
		stringarray=($LINE)
		fileName=${stringarray[1]}
		sourceDir=${stringarray[2]}
		sourcePath=$(dirname $(readlink -f ${sourceDir}))
		sourceName=$(basename ${sourceDir})
		EXECUTABLESCRIPT="tar -C ${sourcePath} -zcvf ./${fileName}.tar.gz ${sourceName} --exclude=\"*.git\" --exclude=\"*.svn\""
	fi

	# Perform no further processing if Feature is Property Loader
	if [ "$feature" != "PROPLD" ]; then
		if [ -n "$EXECUTABLESCRIPT" ]; then
			# Do not echo line if it is an echo itself or it is determining controlled exit
			if [ "${LINE:0:4}" != "echo" ] && [ "$feature" != "EXITIF" ]; then
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
			echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
			exit $exitCode
		fi
	fi
	
done < $TASKLIST
echo
echo "~~~~~~ Shutdown Execution Engine ~~~~~~"
