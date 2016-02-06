#!/usr/bin/env bash
echo
echo "$0 : +--------------------------------+"
echo "$0 : | Process Locally Executed Tasks |"
echo "$0 : +--------------------------------+"
echo
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
echo "$0 :   whoami       : $(whoami)"
echo "$0 :   hostname     : $(hostname)"
cdafVersion=$(./getProperty.sh "./CDAF.properties" "productVersion")
echo "$0 :   CDAF Version : $cdafVersion"

workingDir=$(pwd)
echo "$0 :   workingDir   : $workingDir"

if [ -d "./propertiesForLocalTasks" ]; then

	ls -L -1 ./propertiesForLocalTasks/$ENVIRONMENT* | xargs -n 1 basename > targetList &2> /dev/null

	# Wait for the pipe subprocess to complete 
	wait
	linecount=$(wc -l < "targetList")
	
	if (( $linecount > 0 )); then
		
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
				echo
				echo "./$scriptOverride $SOLUTION $BUILDNUMBER $LOCAL_TASK_TARGET"
				./$scriptOverride "$SOLUTION" "$BUILDNUMBER" "$LOCAL_TASK_TARGET"
				exitCode=$?
				if [ "$exitCode" != "0" ]; then
					echo "$0 : $scriptOverride failed! Returned $exitCode"
					exit $exitCode
				fi
					
			else
			
				echo "$0 :   deployScriptOverride : (property not defined)"
				taskOverride=$(./getProperty.sh "propertiesForLocalTasks/$LOCAL_TASK_TARGET" "deployTaskOverride")
				if [ -z "$taskOverride" ]; then
					taskOverride="./tasksRunLocal.tsk"
					echo "$0 :   deployTaskOverride   : (property not defined, using $taskOverride)"
				else
					echo "$0 :   deployTaskOverride   : $taskOverride"
				fi
				./execute.sh "$SOLUTION" "$BUILDNUMBER" "$LOCAL_TASK_TARGET" "$taskOverride" "$ACTION" 2>&1
				exitCode=$?
				if [ "$exitCode" != "0" ]; then
					echo "$0 : ./execute.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$LOCAL_TASK_TARGET\" \"$taskOverride\" \"$ACTION\" failed! Returned $exitCode"
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
