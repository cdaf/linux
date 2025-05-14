#!/usr/bin/env bash
scriptName='addHOSTS.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	value='172.16.17.102'
	echo "[$scriptName]   value       : $value (default)"
else
	value=$1
	echo "[$scriptName]   value       : $value"
fi

if [ -z "$2" ]; then
	targetfile='server-1.mshome.net'
	echo "[$scriptName]   targetfile : $targetfile (default)"
else
	targetfile=$2
	echo "[$scriptName]   targetfile : $targetfile"
fi

echo "Use hosts entries to provide DNS override"
echo "  sudo sh -c \"echo \"$value\" >> $targetfile\""
sudo sh -c "echo \"$value\" >> $targetfile"
 
echo "[$scriptName] --- end ---"
