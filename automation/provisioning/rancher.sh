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
	echo "[$scriptName]   baseURL            : $baseURL (defaulted from hostname -f)"
else
	echo "[$scriptName]   baseURL            : $baseURL"
fi

installType=$2
if [ -z "$installType" ]; then
	installType='rancher'
	echo "[$scriptName]   installType        : $installType (defaulted, choices rancher or cattle)"
else
	echo "[$scriptName]   installType        : $installType (choices rancher or cattle)"
fi

RANCHER_ACCESS_KEY=$3
if [ -z "$RANCHER_ACCESS_KEY" ]; then
	echo "[$scriptName]   RANCHER_ACCESS_KEY : (not supplied, will look for /vagrant/rancherAPI.key)"
else
	echo "[$scriptName]   RANCHER_ACCESS_KEY : $RANCHER_ACCESS_KEY"
fi

RANCHER_SECRET_KEY=$4
if [ -z "$RANCHER_SECRET_KEY" ]; then
	echo "[$scriptName]   RANCHER_SECRET_KEY : (not supplied, will look for /vagrant/rancherAPI.key)"
else
	echo "[$scriptName]   RANCHER_SECRET_KEY : ****************************************"
fi

if [ "$installType" == "rancher" ]; then
	echo
	echo "[$scriptName] Install Rancher Server container instance"
	executeExpression "sudo docker run -d --restart=unless-stopped --name=rancher-server -p 8080:8080 rancher/server"
	echo
	echo "[$scriptName] List running containers"
	executeExpression "sudo docker ps"
	echo
	echo "[$scriptName] Wait for Rancher server to startup"
	executeExpression "sleep 60"
	echo
	echo "[$scriptName] Verify server responding"
	executeExpression "curl -s http://localhost:8080"
	echo
	export PYTHONIOENCODING=utf8
	echo "[$scriptName] Create API key for PROD"
	executeExpression "curl -s -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{\"accountId\":\"1a1\", \"description\":\"Production Environment\", \"name\":\"PROD\"}' 'http://localhost:8080/v1/apikeys/' -o apiKey.json "
	publicValue=$(cat apiKey.json | python3 -c "import sys, json; print(json.load(sys.stdin)['publicValue'])") 
	secretValue=$(cat apiKey.json | python3 -c "import sys, json; print(json.load(sys.stdin)['secretValue'])") 
	
	# If in a Vagrant environment, export the API key values for use by other guests
	if [ -d "/vagrant" ]; then
		echo "RANCHER_ACCESS_KEY=$publicValue" > /vagrant/rancherAPI.key
		echo "RANCHER_SECRET_KEY=$secretValue" >> /vagrant/rancherAPI.key
		echo
		echo "Administrator keys"
		cat /vagrant/rancherAPI.key
	fi
	echo
	echo "[$scriptName] Set the base URL"
	executeExpression "curl -s -X PUT -H 'Accept: application/json' -H 'Content-Type: application/json' -H 'X-Api-Account-Id: 1a1' -d '{\"activeValue\":\"http://localhost:18080\", \"id\":\"1as1\", \"name\":\"api.host\", \"source\":\"Database\", \"value\":\"http://${baseURL}:8080\"}' 'http://localhost:8080/v1/activesettings/1as!api.host'"
	echo
	echo "[$scriptName] Set the admin user"
	executeExpression "curl -s -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{\"accessMode\":\"unrestricted\", \"enabled\":true, \"name\":\"Administrator\", \"password\":\"password\", \"username\":\"admin\"}' 'http://localhost:8080/v1/localauthconfigs' " 
	
else
	# Derived from http://yayprogramming.com/auto-connect-rancher-hosts/
	if [ -z "$RANCHER_ACCESS_KEY" ]; then
		if [ -d "/vagrant" ]; then
			while read LINE; do
    	        eval "${LINE}"
			done < /vagrant/rancherAPI.key
#			echo "RANCHER_ACCESS_KEY=$RANCHER_ACCESS_KEY"
#			echo "RANCHER_SECRET_KEY=$RANCHER_SECRET_KEY"
		else
			echo "[$scriptName] RANCHER_ACCESS_KEY and /vagrant/rancherAPI.key not found, exiting with error code 100."; exit 100			
		fi
	fi
	echo
	echo
	echo "[$scriptName] Get Project ID"
	echo "[$scriptName] curl -s -u \$KEY $baseURL/v1/projects | jq -r '.data[0].id'"
	KEY="$RANCHER_ACCESS_KEY:$RANCHER_SECRET_KEY"
#	echo "KEY=$KEY"
	PROJECT_ID=$(curl -s -u $KEY $baseURL/v1/projects | jq -r '.data[0].id')

	echo
	echo "[$scriptName] Create registration token using Project ID $PROJECT_ID"
	executeExpression "curl -s -X POST -u \$KEY $baseURL/v1/registrationtokens?projectId=$PROJECT_ID"	
	echo
	echo
	echo "[$scriptName] Get registration token"
	echo "[$scriptName] curl -s -u \$KEY $baseURL/v1/registrationtokens?projectId=$PROJECT_ID | jq -r '.data[0].token'"
	TOKEN=$(curl -s -u $KEY $baseURL/v1/registrationtokens?projectId=$PROJECT_ID | jq -r '.data[0].token')

	if [ "$TOKEN" == "null" ]; then
		echo
		echo "[$scriptName] TOKEN is null, retry ..."
		sleep 5
		TOKEN=$(curl -s -u $KEY $baseURL/v1/registrationtokens?projectId=$PROJECT_ID | jq -r '.data[0].token')
		if [ "$TOKEN" == "null" ]; then
			echo "[$scriptName] TOKEN is null, exiting with error 101."; exit 101
		fi
	fi

	echo
	echo "[$scriptName] Register with token"
	executeExpression "sudo docker run -d --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.1.3 $baseURL/v1/scripts/$TOKEN"
	echo	
fi
echo
echo "[$scriptName] --- end ---"
