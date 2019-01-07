#!/usr/bin/env bash
scriptName='addToFileAs.sh'

echo "[$scriptName] --- start ---"
echo "[$scriptName]   whoami    : $(whoami)"
userName="$1"
if [ -z "$userName" ]; then
	echo "[$scriptName] UserName not supplied, exit 1"; exit 1
else
	echo "[$scriptName]   userName  : $userName"
fi

fileName="$2"
if [ -z "$fileName" ]; then
	echo "[$scriptName] File name not supplied, exit 3"; exit 3
else
	echo "[$scriptName]   fileName  : $fileName"
fi

sensitive="$4"
if [ -z "$sensitive" ]; then
	sensitive='no'
else
	sensitive='yes'
fi

content="$3"
if [ -z "$content" ]; then
	echo "[$scriptName] Content not supplied, exit 3"; exit 3
else
	if [ "$sensitive" == 'no' ]; then
		echo "[$scriptName]   content   : $content"
	else 
		echo "[$scriptName]   content   : *************"
	fi
fi

echo "[$scriptName]   sensitive : $sensitive"
parentDirectory=$(dirname "${fileName}")

su "$userName" << EOF
	if [ ! -d "${parentDirectory}" ]; then
		mkdir -pv ${parentDirectory}
		if [ "$?" != "0" ]; then
			echo "[$scriptName] Failed to create ${parentDirectory}! Exiting with code 34"; exit 34
		fi
	fi
	echo "$content" >> $fileName
	if [ "$?" != "0" ]; then
		echo "[$scriptName] Failed to add content to ${fileName}! Exiting with code 35"; exit 3
	fi
	if [ "$sensitive" == 'no' ]; then
		cat $fileName
	else 
		md5sum $fileName
	fi
EOF

echo "[$scriptName] --- end ---"
