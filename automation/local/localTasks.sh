#!/usr/bin/env bash

function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

echo
echo "$0 : +--------------------------------+"
echo "$0 : | Process Locally Executed Tasks |"
echo "$0 : +--------------------------------+"; echo
if [ -z "$1" ]; then
	echo "$0 Environment Argument not passed. HALT!"
	exit 1
else
	ENVIRONMENT=$1
	echo "$0 :   ENVIRONMENT  : $ENVIRONMENT"
fi

if [ -z "$2" ]; then
	echo "$0 Build Number not passed. HALT!"
	exit 2
else
	BUILDNUMBER=$2
	echo "$0 :   BUILDNUMBER  : $BUILDNUMBER"
fi

if [ -z "$3" ]; then
	echo "$0 : Solution Name not supplied. HALT!"
	exit 3
else
	SOLUTION=$3
	echo "$0 :   SOLUTION     : $SOLUTION"
fi

WORKDIR=$4
# If passed, change to the working directory, if not passed, execute in current directory
if [ "$WORKDIR" ]; then
	cd $WORKDIR
	echo "$0 :   WORKDIR      : $WORKDIR"
else
	echo "$0 :   WORKDIR      : $(pwd) (not passed, using current dir)"
fi

if [ -z "$5" ]; then
	echo "$0 :   OPT_ARG      : (Optional task argument not supplied)"
else
	OPT_ARG=$5
	echo "$0 :   OPT_ARG      : $OPT_ARG"
fi
echo "$0 :   whoami       : $(whoami)"
echo "$0 :   hostname     : $(hostname)"
echo "$0 :   pwd          : $(pwd)"

if [ -d "./propertiesForLocalTasks" ]; then

	find ./propertiesForLocalTasks -name "$ENVIRONMENT*" > targetList
	wait
	linecount=$(wc -l < "targetList")
	if [ "$linecount" -gt 0 ]; then

		ls -L -1 ./propertiesForLocalTasks/$ENVIRONMENT* | xargs -n 1 basename > targetList &2> /dev/null
		# Wait for the pipe subprocess to complete 
		wait
		
		echo
		echo "$0 : Preparing to process targets : "
		echo		 
		while read LIST_TARGET
		do
			echo "  $LIST_TARGET"
		
		done < targetList
				
		while read LOCAL_TASK_TARGET
		do
		
			echo
			echo "$0 :   LOCAL_TASK_TARGET    : $LOCAL_TASK_TARGET"

			scriptOverride=$(./getProperty.sh "propertiesForLocalTasks/$LOCAL_TASK_TARGET" "deployScriptOverride")
			if [ "$scriptOverride" ]; then
				echo "$0 :   deployScriptOverride : $scriptOverride"
			executeExpression "./$scriptOverride '$SOLUTION' '$BUILDNUMBER' '$LOCAL_TASK_TARGET'" 
			else
			
				echo "$0 :   deployScriptOverride : (property not defined)"
				taskOverride=$(./getProperty.sh "propertiesForLocalTasks/$LOCAL_TASK_TARGET" "deployTaskOverride")
				if [ -z "$taskOverride" ]; then
					taskOverride="./tasksRunLocal.tsk"
					echo "$0 :   deployTaskOverride   : (property not defined, using $taskOverride)"
				else
					echo "$0 :   deployTaskOverride   : $taskOverride"
				fi
				if [ ! -f $taskOverride ]; then
					echo "$0 $taskOverride not found! Exit with code 3225"
					exit 3225
				fi
				./execute.sh "$SOLUTION" "$BUILDNUMBER" "$LOCAL_TASK_TARGET" "$taskOverride" "$OPT_ARG" 2>&1
				exitCode=$?
				if [ "$exitCode" != "0" ]; then
					echo "$0 : ./execute.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$LOCAL_TASK_TARGET\" \"$taskOverride\" \"$OPT_ARG\" failed! Returned $exitCode"
					exit $exitCode
				fi
			fi
							
		done < targetList
		
		cd ..
		rm -f targetList
	
	else
		echo
		echo "$0 :   Properties directory ($workingDir/propertiesForLocalTasks) exists but contains no files, no action taken. Check that properties file exists with prefix of $ENVIRONMENT."
		
	fi
else
	echo
	echo "$0 :   Properties directory ($workingDir/propertiesForLocalTasks) not found, no action taken."
fi
