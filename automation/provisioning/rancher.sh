#!/usr/bin/env bash
scriptName='rancher.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	install='agent'
	echo "[$scriptName]   install     : $install (default, choices agent or server)"
else
	install=$1
	echo "[$scriptName]   install     : $install (choices canon or latest)"
fi

# Download and run the Rancher server container
if [ "$install" == 'server' ]; then
	echo "[$scriptName] sudo docker run -d --restart=always -p 8080:8080 rancher/server"
	sudo docker run -d --restart=always -p 8080:8080 rancher/server

	echo "[$scriptName] List running containers"
	sudo docker ps

	echo "[$scriptName] Wait for Rancher server to startup"
	sleep 60
		
    echo "[$scriptName] Create API key for PROD"
    curl -X POST \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{"accountId":"1a1", "description":"Production Environment", "name":"PROD"}' \
    'http://localhost:8080/v1/apikeys/' 
	
	echo "[$scriptName] Set the base URL"
    curl -X PUT \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H 'X-Api-Account-Id: 1a1' \
    -d '{"activeValue":"http://localhost:18080", "id":"1as1", "name":"api.host", "source":"Database", "value":"http://172.16.17.101:8080"}' \
    'http://localhost:8080/v1/activesettings/1as!api.host'

    echo "[$scriptName] Set the admin user"
    curl -X POST \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{"accessMode":"unrestricted", "enabled":true, "name":"Administrator", "password":"password", "username":"admin"}' \
    'http://localhost:8080/v1/localauthconfigs' 

fi
 
echo "[$scriptName] --- end ---"
