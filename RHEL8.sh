#!/usr/bin/env bash
scriptName='RHEL8.sh'

function writeLog {
	echo; echo "[$scriptName][$(date)] $1"
}

function executeExpression {
	writeLog "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		writeLog "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

function executeIgnore {
	writeLog "$1"
	eval $1
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		if [ -z $2 ]; then
			writeLog "$0 : Warning! $EXECUTABLESCRIPT returned $exitCode"
		else
			if [ "$exitCode" == "$2" ]; then
				writeLog "$0 : Warning! $EXECUTABLESCRIPT returned non-zero exit code ${exitCode} but is ignored due to $2 passed as ignored exit code"
			else
				writeLog "$0 : ERROR! $EXECUTABLESCRIPT returned non-zero exit code ${exitCode} and is exiting becuase ignored exist code is $2"
				exit $exitCode
			fi
		fi
	fi

}  

echo; echo "--- start ---"
current_user=$(whoami)
if [[ $current_user != 'root' ]]; then
	elevation='sudo'
fi

echo "  whoami       : $current_user"

if [ ! -z "$HTTP_PROXY" ]; then
	echo "  HTTP_PROXY   : $HTTP_PROXY"
	curlOpt="-x $HTTP_PROXY"
else
	echo "  HTTP_PROXY   : (not set)"
fi

writeLog "Add Extra Packages for Enterprise Linux"
executeIgnore "${elevation} rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
executeExpression "${elevation} yum install -y java-11-openjdk-devel"
 
executeExpression "${elevation} yum install -y snapd"

executeExpression "${elevation} systemctl enable --now snapd.socket"
if [ -e "/snap" ]; then
	writeLog "Unlink any existing configuration"
	executeExpression "${elevation} unlink /snap"
fi

writeLog "To enable classic snap support, en"
executeExpression "${elevation} ln -s /var/lib/snapd/snap /snap"
 
executeExpression "${elevation} snap install --classic eclipse"
 
writeLog "Download Chrome RPM and install using Dandified YUM"
executeExpression "wget --directory-prefix=/tmp/chrome https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
executeExpression "${elevation} dnf localinstall -y /tmp/chrome/google-chrome-stable_current_x86_64.rpm"

writeLog "Add Microsoft Keys for VS Code"
executeExpression "${elevation} rpm --import https://packages.microsoft.com/keys/microsoft.asc"

writeLog "Always overrite to ensure the script config is being used"; echo
sudo tee /etc/yum.repos.d/vscode.repo <<ADDREPO
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
ADDREPO
 
writeLog "Install VS Code"
executeExpression "${elevation} dnf install -y code"

writeLog "Always overrite to ensure the script config is being used"; echo
sudo tee /etc/yum.repos.d/kubernetes.repo <<ADDREPO
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
ADDREPO
 
writeLog "Install K8S CLI"
executeExpression "${elevation} dnf install -y kubectl"

writeLog "Install Git CLI"
executeExpression "${elevation} dnf install -y git"

writeLog "dotnet core"
executeExpression "${elevation} dnf install -y dotnet-sdk-6.0"

writeLog "NodeJS"
executeExpression "${elevation} dnf module install -y nodejs:16"

writeLog "Buildah & Podman"
executeExpression "${elevation} yum install -y podman-docker"
executeExpression "${elevation} touch /etc/containers/nodocker"

writeLog "--- end ---"
exit 0
