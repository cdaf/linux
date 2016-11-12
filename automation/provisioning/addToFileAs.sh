#!/usr/bin/env bash
scriptName='addToFileAs.sh'

echo "[$scriptName] --- start ---"
echo "[$scriptName]   whoami   : $(whoami)"
userName="$1"
if [ -z "$userName" ]; then
	echo "[$scriptName] UserName not supplied, exit 1"; exit 1
else
	echo "[$scriptName]   userName : $userName"
fi

fileName="$2"
if [ -z "$fileName" ]; then
	echo "[$scriptName] File name not supplied, exit 3"; exit 3
else
	echo "[$scriptName]   fileName : $fileName"
fi

content="$3"
if [ -z "$content" ]; then
	echo "[$scriptName] Content not supplied, exit 2"; exit 2
else
	echo "[$scriptName]   content  : $content"
fi

su $userName << EOF
	echo "$content" >> $fileName
	cat $fileName
EOF

echo "[$scriptName] --- end ---"
