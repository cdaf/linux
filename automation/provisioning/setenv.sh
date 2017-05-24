#!/usr/bin/env bash
scriptName='setenv.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "variable not passed, HALT!"
	exit 1
else
	variable="$1"
	# The variable name will be used as the script name
	echo "[$scriptName]   variable : $variable"
fi

if [ -z "$2" ]; then
	echo "Value not passed, HALT!"
	exit 1
else
	value="$2"
	echo "[$scriptName]   value    : $value"
fi

level="$3"
if [ -z "$level" ]; then
	level='machine'
	echo "[$scriptName]   level    : $level (default)"
else
	if [ "$level" == 'machine' ] || [ "$level" == 'user' ]; then
		echo "[$scriptName]   level    : $level"
	else
		echo "[$scriptName] level must be machine or user, exiting with code 3"; exit 3
	fi
fi

if [ "$level" == 'user' ]; then

	echo export $variable=\"$value\" >> $HOME/.bashrc
	
	# Execute the script to set the variable 
	source $HOME/.bashrc

else

	# Set environment (user default) variable
	systemLocation='/etc/profile.d/'
	startScript="$variable"
	startScript+='.sh'
	echo "[$scriptName] export $variable=\"$value\" > $startScript"
	echo export $variable=\"$value\" > $startScript
	echo "[$scriptName] chmod +x $startScript"
	chmod +x $startScript
	echo "[$scriptName] sudo cp -rv $startScript $systemLocation"
	sudo cp -rv $startScript $systemLocation
	rm $startScript
	
	# Execute the script to set the variable 
	source $systemLocation/$startScript

fi

echo "[$scriptName] --- end ---"
