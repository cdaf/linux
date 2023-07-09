#!/usr/bin/env bash

# Install is for Ubuntu only
# curl -s https://raw.githubusercontent.com/cdaf/linux/master/bootstrap-dev.sh | bash -

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

function executeYumCheck {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval $1
		exitCode=$?
		# Exit 0 and 100 are both success
		if [ "$exitCode" == "100" ] || [ "$exitCode" == "0" ]; then
			success='yes'
		else
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		fi
	done
}

scriptName='bootstrap-dev.sh'
echo "[$scriptName] --- start ---"
user_name=$(whoami)
if [ "$user_name" == 'root' ]; then
	echo "[$scriptName]   whoami : ${user_name}"
else
	echo "[$scriptName]   whoami : ${user_name} (use sudo to elevate)"
	elevate='sudo'
fi
echo

# First check for CDAF in current directory, then check for a Vagrant VM, if not Vagrant
if [ -f './automation/CDAF.linux' ]; then
	atomicPath='./automation/provisioning'
	echo "[$scriptName] atomicPath = $atomicPath ..."
else
	echo "[$scriptName] Provisioning directory ($atomicPath) not found in workspace, looking for alternative ..."
	if [ -f '/vagrant/automation/CDAF.linux' ]; then
		atomicPath='/vagrant/automation/provisioning'
		echo "[$scriptName] atomicPath = $atomicPath ..."
	else
		echo "[$scriptName] $atomicPath not found for Vagrant, download latest from GitHub"
		executeExpression "curl -s https://raw.githubusercontent.com/cdaf/linux/master/install.sh | bash -"
		atomicPath='./automation/provisioning'
		echo "[$scriptName] atomicPath = $atomicPath ..."
	fi
fi

echo; echo "[$scriptName] Install Google Chrome"; echo
chromePackage='./google-chrome-stable_current_amd64.deb'	
if [ -f "${chromePackage}" ]; then
	executeExpression "rm -f ${chromePackage}"
fi

executeExpression "wget --quiet https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

executeExpression "$elevate apt-get install -y ${chromePackage}"
executeExpression "google-chrome -version"
executeExpression "rm -f ${chromePackage}"

executeExpression "$elevate ${atomicPath}/base.sh 'virtualbox vagrant'"

executeExpression "$elevate ${atomicPath}/base.sh 'wget gnupg2 apt-transport-https ca-certificates'"

executeExpression "wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | $elevate apt-key add -"
executeExpression "echo \"deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main\" | $elevate tee /etc/apt/sources.list.d/adoptium.list"
executeExpression "$elevate ${atomicPath}/base.sh 'temurin-11-jdk'"

if [[ "$2" == 'jdk' ]]; then
	javaCompiler=$(which javac)
	javaBin=$(dirname $(readlink -f $javaCompiler))
	javaHome=${javaBin%/*}
	executeExpression "$elevate ${atomicPath}/setenv.sh JAVA_HOME $javaHome"
fi

echo "[$scriptName] The base command refreshes the repositories"; echo
echo "[$scriptName] From https://code.visualstudio.com/docs/setup/linux"
test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Debian/Ubuntu"
	executeExpression "curl https://packages.microsoft.com/keys/microsoft.asc | $elevate gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg"
	executeExpression "sh -c 'echo \"deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main\" > /etc/apt/sources.list.d/vscode.list'"
	executeExpression "$elevate apt-get update"
	executeExpression "$elevate apt-get install -y code"
fi

executeExpression "${atomicPath}/installDocker.sh" # Docker and Compose
# executeExpression "${atomicPath}/installOracleJava.sh jdk" # Docker and Compose

echo "[$scriptName] --- end ---"
