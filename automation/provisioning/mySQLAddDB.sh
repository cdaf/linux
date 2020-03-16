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

scriptName='mySQLAddDB.sh'

echo "[$scriptName] --- start ---"
dbPassword="$1"
if [ -z "$dbPassword" ]; then
	echo "[$scriptName] Error, dbPassword not supplied!"; exit 6112
else
	echo "[$scriptName]   dbPassword : ****************"
fi

dbName="$2"
if [ -z "$dbName" ]; then
	dbName='mydb'
	echo "[$scriptName]   dbName     : $dbName (default)"
else
	echo "[$scriptName]   dbName     : $dbName"
fi

dbUser="$3"
if [ -z "$dbUser" ]; then
	dbUser='mydatabaseuser'
	echo "[$scriptName]   dbUser     : $dbUser (default)"
else
	echo "[$scriptName]   dbUser     : $dbUser"
fi

adminPass="$4"
if [ -z "$adminPass" ]; then
	echo "[$scriptName]   adminPass  : (none)"
else
	echo "[$scriptName]   adminPass  : ****************"
	admin="-p${adminPass}"
fi

if [ -z "$adminPass" ]; then
	userExists=$(mysql -u root --silent --skip-column-names  -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$dbUser')" 2>1 | grep -v Warning)
else
	userExists=$(mysql -u root -p$adminPass --silent --skip-column-names  -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$dbUser')" 2>1 | grep -v Warning)
fi
	
if [[ $userExists == '1' ]]; then
	echo "[$scriptName] User $dbUser exists"
else
	executeExpression "mysql -u root ${admin} -e \"CREATE USER '$dbUser'@'localhost';\""
fi

echo "[$scriptName] Create database, ignore error if exists"
executeExpression "mysql -u root ${admin} -e 'CREATE DATABASE IF NOT EXISTS ${dbName};'"

echo; echo "[$scriptName] Set database owners, these can be rerun"
executeExpression "mysql -u root ${admin} -e \"GRANT USAGE ON *.* TO ${dbUser}@localhost IDENTIFIED BY '\${dbPassword}';\""
executeExpression "mysql -u root ${admin} -e \"GRANT ALL PRIVILEGES ON ${dbName}.* TO ${dbUser}@localhost;\""

echo; echo "[$scriptName] Verify"
executeExpression "mysql -u ${dbUser} -p\${dbPassword} -e 'SHOW DATABASES'"

echo "[$scriptName] --- end ---"

