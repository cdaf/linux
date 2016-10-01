#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='postGreSQLAddDB.sh'

echo "[$scriptName] --- start ---"
dbName="$1"
if [ -z "$dbName" ]; then
	dbName='mydb'
	echo "[$scriptName]   dbName     : $dbName (default)"
else
	echo "[$scriptName]   dbName     : $dbName"
fi

dbUser="$2"
if [ -z "$dbUser" ]; then
	dbUser='mydatabaseuser'
	echo "[$scriptName]   dbUser     : $dbUser (default)"
else
	echo "[$scriptName]   dbUser     : $dbUser"
fi

dbPassword="$3"
if [ -z "$dbPassword" ]; then
	dbPassword='secretPassw0rd'
	echo "[$scriptName]   dbPassword : $dbPassword (default)"
else
	echo "[$scriptName]   dbPassword : ****************"
fi

sqlScriptFile='/tmp/newDB.sql'

executeExpression "sudo -u postgres createdb $dbName"
executeExpression "sudo -u postgres createuser --echo $dbUser"
executeExpression "echo \"alter user mydatabaseuser password '\$dbPassword';\" > $sqlScriptFile"
executeExpression "sudo -u postgres psql -d $dbName -f $sqlScriptFile"

echo "[$scriptName] --- end ---"

