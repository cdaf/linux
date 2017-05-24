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

scriptName='mySQLAddDB.sh'

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
	echo "[$scriptName]   dbPassword : (none)"
else
	echo "[$scriptName]   dbPassword : ****************"
fi

if [ -z "$dbPassword" ]; then
	echo "[$scriptName] Create database, ignore error if exists"
	mysql -u root -e "create database ${dbName};"
	echo
	echo "[$scriptName] Set database owners, these can be rerun"
	mysql -u root -e "grant usage on *.* to ${dbUser}@localhost identified by '${dbPassword}';"
	mysql -u root -e "grant all privileges on ${dbName}.* to ${dbUser}@localhost;"
else
	echo "[$scriptName] Create database, ignore error if exists"
	mysql -u root --password=${dbPassword} -e "create database ${dbName};"
	echo
	echo "[$scriptName] Set database owners, these can be rerun"
	mysql -u root --password=${dbPassword} -e "grant usage on *.* to ${dbUser}@localhost identified by '${dbPassword}';"
	mysql -u root --password=${dbPassword} -e "grant all privileges on ${dbName}.* to ${dbUser}@localhost;"
fi

echo "[$scriptName] --- end ---"

