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

if [ -d './automation' ]; then
	atomicPath='.'
else
	echo "[$scriptName] Provisioning directory ($atomicPath) not found in workspace, looking for alternative ..."
	if [ -d '/vagrant/automation' ]; then
		atomicPath='/vagrant'
	else
		echo "[$scriptName] $atomicPath not found for either Docker or Vagrant, will download latest"
		executeExpression "curl -s -O http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
		executeExpression "tar -xzf LU-CDAF.tar.gz"
		atomicPath='/vagrant'
	fi
fi

echo; echo "[$scriptName] atomicPath = $atomicPath"

echo; echo "[$scriptName] JSON deserialising tool ..."
executeExpression "$elevate $atomicPath/automation/provisioning/base.sh jq"

echo
test="`curl --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] curl not installed, required to download Terraform binary, install using package manager ..."
	executeExpression "$atomicPath/automation/provisioning/base.sh curl"
	executeExpression "curl --version"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] curl : $test"
fi	

test="`unzip --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] unzip not installed, required to extract Terraform & AWS CLI 2 binary, install using package manager ..."
	executeExpression "$atomicPath/automation/provisioning/base.sh unzip"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] unzip : $test"
fi	

echo
echo "[$scriptName] Install AWS CLI 2 is now a self contained install"
executeExpression 'curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"'
executeExpression 'unzip awscliv2.zip'
executeExpression "$elevate ./aws/install"

echo
version='0.12.26'
echo "[$scriptName] Install Terraform ${version}"
executeExpression "curl -s -O https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip"
executeExpression "unzip terraform_${version}_linux_amd64.zip"
executeExpression "$elevate mv terraform /usr/bin/"
executeExpression "terraform --version"

echo
echo "[$scriptName] --- end ---"