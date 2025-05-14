#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='computerCertificate.sh'

echo "[$scriptName] --- start ---"
commonName=$1
echo "[$scriptName]   commonName : $commonName"

executeExpression "openssl genrsa -des3 -passout pass:x -out temp.key 2048"
executeExpression "openssl rsa -passin pass:x -in temp.key -out ${commonName}.key"
executeExpression "rm temp.key"
executeExpression "openssl req -new -key ${commonName}.key -out ${commonName}.csr -subj '/C=UK/ST=Warwickshire/L=Leamington/O=OrgName/OU=IT Department/CN=${commonName}'"
executeExpression "openssl x509 -req -days 365 -in ${commonName}.csr -signkey ${commonName}.key -out ${commonName}.crt"
executeExpression "cat ${commonName}.crt > ${commonName}.pem"
executeExpression "cat ${commonName}.key >> ${commonName}.pem"
    
echo "[$scriptName] --- end ---"
