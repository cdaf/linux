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

scriptName='bootstrapAgent.sh'

echo "[$scriptName] --- start ---"
echo "[$scriptName] Working directory is $(pwd)"
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami  : $(whoami)"
else
	echo "[$scriptName]   whoami  : $(whoami) (elevation not required)"
fi

echo; echo "[$scriptName] JSON deserialising tool ..."
executeExpression "$elevate ./base.sh jq"

echo
test="`curl --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] curl not installed, required to download Terraform binary, install using package manager ..."
	executeExpression "./base.sh curl"
	executeExpression "curl --version"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] curl : $test"
fi	

test="`unzip --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] unzip not installed, required to extract Terraform & AWS CLI 2 binary, install using package manager ..."
	executeExpression "./base.sh unzip"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] unzip : $test"
fi	

echo
echo "[$scriptName] Required tools, e.g. AWS CLI, Azure CLI, Terraform, Helm"
#version='0.12.26'
#echo "[$scriptName] Install Terraform ${version}"
#executeExpression "curl -s -O https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip"
#executeExpression "unzip terraform_${version}_linux_amd64.zip"
#executeExpression "$elevate mv terraform /usr/bin/"
#executeExpression "terraform --version"

echo
echo "[$scriptName] --- end ---"
