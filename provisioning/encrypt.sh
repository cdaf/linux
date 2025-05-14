#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName]   $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  
scriptName='encrypt.sh'
echo
echo "[$scriptName] --- start ---"
inputFile=$1
if [ -z "$inputFile" ]; then
	echo "[$scriptName]   inputFile not supplied!"; exit 101
else
	echo "[$scriptName]   inputFile     : $inputFile"
fi

encryptedFile=$2
if [ -z "$encryptedFile" ]; then
	encryptedFile=$inputFile
	echo "[$scriptName]   encryptedFile : (not suppplied, existing file will be replaced)"
else
	echo "[$scriptName]   encryptedFile : $encryptedFile"
fi

stringKeyIn=$3
if [ -z "$stringKeyIn" ]; then
	echo "[$scriptName]   stringKeyIn   : (not supplied, key will be generated, e.g. 8b778ff3fd80def90161e40b9c54527e)"
	IFS=' ' read -ra ADDR <<< $(date | md5sum)
	key=${ADDR[0]}
else
	key=$stringKeyIn
	echo "[$scriptName]   stringKeyIn   : \$key (e.g. 8b778ff3fd80def90161e40b9c54527e)"
fi

gpg --cipher-algo AES256 --symmetric --batch --passphrase $key --output $encryptedFile $inputFile

if [ -z "$stringKeyIn" ]; then
	echo $key
fi
echo "[$scriptName] --- end ---"
