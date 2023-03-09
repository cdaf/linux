#!/usr/bin/env bash
# Cannot perform logging because the return value is anything echoed

set -e
scriptName=${0##*/}

encryptedFile=$1
if [ -z "$1" ]; then
	echo "encryptedFile not supplied. HALT!"; exit 101
fi

passphrase=$2

# If a passphrase not supplied, attempt to decrypting using users ssh private key
if [ -z "$2" ]; then
	privateKey=$(./getProperty.sh "./$TARGET" "privateKey")
	if [ -z "$privateKey" ]; then
		privateKey="$HOME/.ssl/private_key.pem"
	fi
	
	# This return value should be consumed by a variable and not logged 
	openssl rsautl -decrypt -inkey $privateKey -in $encryptedFile
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Unable to decrypt $CRYPTFILE! Returned $exitCode"
		exit $exitCode
	fi
else
	test="`gpg --version 2>&1`"
	if [[ "$test" == *"not found"* ]]; then
		gpg2 --decrypt  --batch --passphrase ${passphrase} ${encryptedFile}
	else
		gpg --decrypt  --batch --passphrase ${passphrase} ${encryptedFile}
	fi
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Unable to decrypt $CRYPTFILE! Returned $exitCode"
		exit $exitCode
	fi
fi
