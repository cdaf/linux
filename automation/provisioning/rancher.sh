#!/usr/bin/env bash

function executeExpression {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval $1
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		else
			success='yes'
		fi
	done
}  

scriptName='rancher.sh'

echo "[$scriptName] --- start ---"
baseURL=$1
if [ -z "$baseURL" ]; then
	baseURL=$(hostname -f)
	echo "[$scriptName]   baseURL     : $baseURL (defaulted from hostname -f)"
else
	echo "[$scriptName]   baseURL     : $baseURL"
fi

echo "[$scriptName] Install Rancher Server container instance"
executeExpression "sudo docker run -d --restart=always -p 8080:8080 rancher/server"

echo "[$scriptName] List running containers"
executeExpression "sudo docker ps"

echo "[$scriptName] Wait for Rancher server to startup"
executeExpression "sleep 60"

export PYTHONIOENCODING=utf8
echo "[$scriptName] Create API key for PROD"
executeExpression "curl -s -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{\"accountId\":\"1a1\", \"description\":\"Production Environment\", \"name\":\"PROD\"}' 'http://localhost:8080/v1/apikeys/' -o apiKey.json "
publicValue=$(cat apiKey.json | python3 -c "import sys, json; print(json.load(sys.stdin)['publicValue'])") 
secretValue=$(cat apiKey.json | python3 -c "import sys, json; print(json.load(sys.stdin)['secretValue'])") 

echo "[$scriptName] Set the base URL"
executeExpression "curl -s -X PUT -H 'Accept: application/json' -H 'Content-Type: application/json' -H 'X-Api-Account-Id: 1a1' -d '{\"activeValue\":\"http://localhost:18080\", \"id\":\"1as1\", \"name\":\"api.host\", \"source\":\"Database\", \"value\":\"http://${baseURL}:8080\"}' 'http://localhost:8080/v1/activesettings/1as!api.host'"

echo "[$scriptName] Set the admin user"
executeExpression "curl -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{\"accessMode\":\"unrestricted\", \"enabled\":true, \"name\":\"Administrator\", \"password\":\"password\", \"username\":\"admin\"}' 'http://localhost:8080/v1/localauthconfigs' " 

echo "[$scriptName] --- end ---"
