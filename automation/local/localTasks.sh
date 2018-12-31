#!/usr/bin/env bash
scriptName=${0##*/}

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

echo
echo "[$scriptName] +--------------------------------+"
echo "[$scriptName] | Process Locally Executed Tasks |"
echo "[$scriptName] +--------------------------------+"; echo
if [ -z "$1" ]; then
	echo "$scriptName Environment Argument not passed. HALT!"
	exit 1
else
	ENVIRONMENT=$1
	echo "[$scriptName]   ENVIRONMENT  : $ENVIRONMENT"
fi

if [ -z "$2" ]; then
	echo "$scriptName Build Number not passed. HALT!"
	exit 2
else
	BUILDNUMBER=$2
	echo "[$scriptName]   BUILDNUMBER  : $BUILDNUMBER"
fi

if [ -z "$3" ]; then
	echo "[$scriptName] Solution Name not supplied. HALT!"
	exit 3
else
	SOLUTION=$3
	echo "[$scriptName]   SOLUTION     : $SOLUTION"
fi

WORKDIR=$4
# If passed, change to the working directory, if not passed, execute in current directory
if [ "$WORKDIR" ]; then
	cd $WORKDIR
	echo "[$scriptName]   WORKDIR      : $WORKDIR"
else
	echo "[$scriptName]   WORKDIR      : $(pwd) (not passed, using current dir)"
fi

if [ -z "$5" ]; then
	echo "[$scriptName]   OPT_ARG      : (Optional task argument not supplied)"
else
	OPT_ARG=$5
	echo "[$scriptName]   OPT_ARG      : $OPT_ARG"
fi
echo "[$scriptName]   whoami       : $(whoami)"
echo "[$scriptName]   hostname     : $(hostname)"
echo "[$scriptName]   pwd          : $(pwd)"

if [ -d "./propertiesForLocalTasks" ]; then

	taskList=$(find ./propertiesForLocalTasks -name "$ENVIRONMENT*" )
	if [ -n "$taskList" ]; then
		echo; echo "[$scriptName] Preparing to process targets : "; echo		 
		for LOCAL_TASK_TARGET in $taskList; do
			echo "  ${LOCAL_TASK_TARGET##*/}"
		done
				
		for LOCAL_TASK_TARGET in $taskList; do
			LOCAL_TASK_TARGET=${LOCAL_TASK_TARGET##*/}
			echo
			echo "[$scriptName]   LOCAL_TASK_TARGET    : $LOCAL_TASK_TARGET"

			scriptOverride=$(./getProperty.sh "propertiesForLocalTasks/$LOCAL_TASK_TARGET" "deployScriptOverride")
			if [ "$scriptOverride" ]; then
				echo "[$scriptName]   deployScriptOverride : $scriptOverride"
			executeExpression "./$scriptOverride '$SOLUTION' '$BUILDNUMBER' '$LOCAL_TASK_TARGET'" 
			else
			
				echo "[$scriptName]   deployScriptOverride : (property not defined)"
				taskOverride=$(./getProperty.sh "propertiesForLocalTasks/$LOCAL_TASK_TARGET" "deployTaskOverride")
				if [ -z "$taskOverride" ]; then
					taskOverride="./tasksRunLocal.tsk"
					echo "[$scriptName]   deployTaskOverride   : (property not defined, using $taskOverride)"
				else
					echo "[$scriptName]   deployTaskOverride   : $taskOverride"
				fi
				for overrideTask in $taskOverride; do
					echo; echo "[$scriptName] Execute $overrideTask"
					if [ ! -f "$overrideTask" ]; then
						echo "[$scriptName][ERROR] $overrideTask not found! List workspace contents and exit with code 3225"
						ls -al
						exit 3225
					fi
					./execute.sh "$SOLUTION" "$BUILDNUMBER" "$LOCAL_TASK_TARGET" "$overrideTask" "$OPT_ARG" 2>&1
					exitCode=$?
					if [ "$exitCode" != "0" ]; then
						echo "[$scriptName] ./execute.sh \"$SOLUTION\" \"$BUILDNUMBER\" \"$LOCAL_TASK_TARGET\" \"$overrideTask\" \"$OPT_ARG\" failed! Returned $exitCode"
						exit $exitCode
					fi
				done
			fi
							
		done
		
		cd ..
	
	else
		echo
		echo "[$scriptName]   Properties directory ($workingDir/propertiesForLocalTasks) exists but contains no files, no action taken. Check that properties file exists with prefix of $ENVIRONMENT."
		
	fi
else
	echo
	echo "[$scriptName]   Properties directory ($workingDir/propertiesForLocalTasks) not found, no action taken."
fi
