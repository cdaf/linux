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

echo "[$scriptName] --- end ---"
