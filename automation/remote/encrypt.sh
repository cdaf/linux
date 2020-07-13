#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# No arguments expected, string (password) to be encrypted is captured from user 

echo
echo "$scriptName +------------------+"
echo "$scriptName | Encrypt password |"
echo "$scriptName +------------------+"
echo
sslHome="$HOME/.ssl"
privateKey="$sslHome/private_key.pem"
publicKey="$sslHome/public_key.pem"
	
if [ ! -d "$sslHome" ]; then
	echo "[$scriptName] Create $sslHome"
	mkdir $sslHome
	chmod 700 $sslHome
fi

if [ ! -f "$privateKey" ]; then
	echo "[$scriptName] Create $privateKey"
	openssl genrsa -out $privateKey 2048
	chmod 600 $privateKey
	openssl rsa -in $privateKey -out $publicKey -outform PEM -pubout
fi

currentDir=$(pwd)
cd $sslHome
printf "Enter password to encrypt : "
read -s password
echo $password | openssl rsautl -encrypt -inkey $publicKey -pubin -out encrypt.dat
echo
echo
mv encrypt.dat $currentDir
cd $currentDir
