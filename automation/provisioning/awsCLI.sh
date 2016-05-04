#!/usr/bin/env bash
set -e

scriptName='awsCLI.sh'
echo
echo "[$scriptName] Install AWS Command Line Interface with Python"
echo
echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "AccessKeyID not passed, no action attempted."
	exit 0
else
	AccessKeyID="$1"
	echo "[$scriptName]   AccessKeyID     : **************"
fi

if [ -z "$2" ]; then
	echo "SecretAccessKey not passed, HALT!"
	exit 2
else
	SecretAccessKey="$2"
	echo "[$scriptName]   SecretAccessKey : **************"
fi

if [ -z "$3" ]; then
	echo "[$scriptName]   awsUser         : root (default)"
else
	awsUser="$3"
	echo "[$scriptName]   awsUser         : $awsUser"
fi

echo "[$scriptName] List the Python version, requires Python 2 version 2.6.5+ or Python 3 version 3.3+"
python --version

echo "[$scriptName] Install PIP"
echo "[$scriptName] Download latest PIP script and execute (Python script, so setting executable not required)"
curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | sudo python

sudo pip install awscli
echo
echo "[$scriptName] Set credentials (~/.aws/credentials)"
if [ -z "$awsUser" ]; then

	if [ ! -d ~/.aws ]; then
		mkdir -pv ~/.aws
	fi
	echo "[default]" > ~/.aws/credentials
	chmod 0600 ~/.aws/credentials
	echo "aws_access_key_id = $AccessKeyID" >> ~/.aws/credentials
	echo "aws_secret_access_key = $SecretAccessKey" >> ~/.aws/credentials
	echo
	echo "[$scriptName] Verify configuration has been set and recognised"
	aws configure list

else # cannot indent or EOF will not be detected
su $awsUser << EOF

	if [ ! -d ~/.aws ]; then
		mkdir -pv ~/.aws
	fi
	echo "[default]" > ~/.aws/credentials
	chmod 0600 ~/.aws/credentials
	echo "aws_access_key_id = $AccessKeyID" >> ~/.aws/credentials
	echo "aws_secret_access_key = $SecretAccessKey" >> ~/.aws/credentials
	echo
	echo "[$scriptName] Verify configuration has been set and recognised"
	aws configure list

EOF
fi

echo "[$scriptName] --- end ---"
