#!/usr/bin/env bash
scriptName='pushToRegistry.sh'
echo
echo "[$scriptName] Upload to AWS ECS Registry."
echo
echo "[$scriptName] --- start ---"
echo
if [ -f ~/.aws/credentials ]; then
	echo "[$scriptName] AWS Credentials set :"
	echo
	aws configure list
else
	echo "[$scriptName] AWS Credentials not provisioned, no action attempted."
	exit 0
fi
echo
echo "[$scriptName] Get login token"
token=$(aws ecr get-login --region us-east-1) 

echo
echo "[$scriptName] Login with token"
echo $token | cut -c1-100
echo "..."
echo $token | tail -c 50
eval $token

echo
echo "[$scriptName] List images ..."
docker images

echo
echo "[$scriptName] Tag the image in the AWS repository"
docker tag -f gateway_container:latest 555005683991.dkr.ecr.us-west-2.amazonaws.com/gateway_container:latest 

# docker login --username=ecspush --email=cloudygoodness@gmail.com

echo "[$scriptName] push this image to your newly created AWS repository"
docker push 555005683991.dkr.ecr.us-west-2.amazonaws.com/gateway_container:latest

echo "[$scriptName] --- end ---"
