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
	dbUser='postgres'
	echo "[$scriptName]   dbUser     : $dbUser (default)"
else
	echo "[$scriptName]   dbUser     : $dbUser"
fi

dbPassword="$3"
if [ -z "$dbPassword" ]; then
	echo "[$scriptName]   dbPassword : (not passed, will not be set)"
else
	echo "[$scriptName]   dbPassword : ****************"
fi
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

sqlScriptFile='/tmp/newDB.sql'

echo "[$scriptName] Create the database $dbName"
executeExpression "$elevate su - postgres -c \"createdb $dbName\""

echo "[$scriptName] Only attempt to create user is not postgres"
if [ "$dbUser" != 'postgres' ]; then
	executeExpression "$elevate su - postgres -c \"createuser --echo $dbUser\""
fi

echo "[$scriptName] Set the DB password if supplied"
if [ -n "$dbPassword" ]; then
	executeExpression "echo \"alter user $dbUser password '\$dbPassword';\" > $sqlScriptFile"
	executeExpression "$elevate su - postgres -c \"psql -d $dbName -f $sqlScriptFile\""
fi

echo "[$scriptName] --- end ---"

