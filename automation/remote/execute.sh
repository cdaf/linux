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

ACTION=$5

echo "$0 :   SOLUTION    : $SOLUTION"
echo "$0 :   BUILDNUMBER : $BUILDNUMBER"
echo "$0 :   TARGET      : $TARGET"
echo "$0 :   TASKLIST    : $TASKLIST"
echo "$0 :   ACTION      : $ACTION"
echo
# to provide exception handling / termination, the deploy script loops through
# main.deploy, which is simply shell script lines, but after each line is executed
# a test on the exit code is performed, there an error is encountered, diagnostics
# are reported and the deploy process halts.

# If this is a build process, load build properties file as variables (this is not required in the PowerShell version as calling program variables are global
AUTOMATIONHELPER=.
if [ -f "../build.properties" ] ;then
	eval $(cat ../build.properties)
	AUTOMATIONHELPER="../$AUTOMATIONROOT/remote"
	rm ../build.properties
fi

if [ -f "./package.properties" ] ;then
	eval $(cat ./package.properties)
	AUTOMATIONHELPER="./$AUTOMATIONROOT/remote"
	rm ./package.properties
fi

# Process Script List
while read LINE
do
	# Execute the script, logging is left to the invoked script, unless an exception occurs
	EXECUTABLESCRIPT=$(echo $LINE | cut -d '#' -f 1)
	if [ -n "$EXECUTABLESCRIPT" ]; then
		# Do not echo line if it is an echo itself
		if [ "${LINE:0:4}" != "echo" ]; then
			echo "$0 : $EXECUTABLESCRIPT"
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
	
	if [ "$terminate" == "clean" ]; then
		echo "$0 : Clean only"
		exit
	fi

	# Load all properties as runtime variables (the utility will provide logging)
	# Test for running as deploy process or build process
	if [ ! -z $loadProperties ]; then

		echo "PROPFILE : $loadProperties"
		propertiesList=$($AUTOMATIONHELPER/transform.sh "$loadProperties")
		printf "$propertiesList"
		eval $propertiesList
		echo			
		loadProperties=""
		
	fi
	
done < $TASKLIST
