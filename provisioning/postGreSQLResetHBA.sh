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

scriptName='postGreSQLResetHBA.sh'

echo "[$scriptName] --- start ---"
type="$1"
if [ -z "$type" ]; then
	type='host'
	echo "[$scriptName]   type     : $type (default)"
else
	echo "[$scriptName]   type     : $type"
fi

database="$2"
if [ -z "$database" ]; then
	database='all'
	echo "[$scriptName]   database : $database (default)"
else
	echo "[$scriptName]   database : $database"
fi

user="$3"
if [ -z "$user" ]; then
	user='all'
	echo "[$scriptName]   user     : $user (default)"
else
	echo "[$scriptName]   user     : $user"
fi

address="$4"
if [ -z "$address" ]; then
	address='127.0.0.1/32'
	echo "[$scriptName]   address  : $address (default)"
else
	echo "[$scriptName]   address  : $address"
fi

method="$5"
if [ -z "$method" ]; then
	method='trust'
	echo "[$scriptName]   method   : $method (default, choices, peer, md5, trust)"
else
	echo "[$scriptName]   method   : $method (choices, peer, md5, trust)"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami   : $(whoami)"
else
	echo "[$scriptName]   whoami   : $(whoami) (elevation not required)"
fi

echo
echo " [$scriptName] Retrieve the path to the configuration file"
echo " [$scriptName] configPath=\$($elevate su - postgres -c 'psql --command \"SHOW hba_file;\" | grep pg_hba.conf')"
configPath=$($elevate su - postgres -c 'psql --command "SHOW hba_file;" | grep pg_hba.conf')
echo
echo " [$scriptName] Reset $configPath to local access only."
echo

executeExpression "$elevate su - postgres -c \"echo '# TYPE  DATABASE        USER            ADDRESS                 METHOD' > $configPath\""
executeExpression "$elevate su - postgres -c \"echo 'local   all             postgres                                peer' >> $configPath\""
executeExpression "$elevate su - postgres -c \"echo 'local   all             all                                     peer' >> $configPath\""

echo " [$scriptName] List the configuration $configPath"
$elevate su - postgres -c "cat $configPath"

echo
executeExpression "$elevate service postgresql restart"

echo "[$scriptName] --- end ---"
