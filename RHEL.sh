#!/usr/bin/env bash
# curl -s https://raw.githubusercontent.com/cdaf/linux/master/RHEL.sh | bash -
scriptName='RHEL.sh'

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

function executeRetry {
	wait="$2"
	if [ -z "$wait" ]; then
		wait=10
		echo "[$scriptName]   wait      : $wait (default, seconds)"
	else
		echo "[$scriptName]   wait      : $wait (seconds)"
	fi
	
	retryMax="$3"
	if [ -z "$retryMax" ]; then
		retryMax=20
		echo "[$scriptName]   retryMax  : $retryMax (default)"
	else
		echo "[$scriptName]   retryMax  : $retryMax"
	fi
	
	counter=1
	success='no'
	while [ "$success" != 'yes' ]; do
		writeLog "[$scriptName][$counter] $1"
		eval $1
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			counter=$((counter + 1))
			if [ "$counter" -le "$retryMax" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Wait $wait seconds, then retry $counter of ${retryMax}"
				sleep $wait
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Maximum retries (${retryMax}) reached."
				exit $exitCode
			fi					 
		else
			success='yes'
		fi
	done
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

IFS='-' read -ra ADDR <<< $(rpm --query redhat-release)
IFS='.' read -ra ADDR <<< ${ADDR[2]}
echo "  RHEL Version : ${ADDR[0]}"

writeLog "Add Extra Packages for Enterprise Linux"
executeIgnore "${elevation} rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-${ADDR[0]}.noarch.rpm"
executeExpression "${elevation} yum install -y java-11-openjdk-devel"
 
executeExpression "${elevation} yum install -y snapd wget"

executeExpression "${elevation} systemctl enable --now snapd.socket"
if [ -e "/snap" ]; then
	writeLog "Unlink any existing configuration"
	executeExpression "${elevation} unlink /snap"
fi

writeLog "To enable classic snap support, en"
executeExpression "${elevation} ln -s /var/lib/snapd/snap /snap"

# executeRetry "${elevation} snap install --classic eclipse"
# executeExpression "${elevation} snap install powershell --classic"
 
writeLog "Download Chrome RPM and install using Dandified YUM"
executeExpression "wget --directory-prefix=/tmp/chrome https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
executeExpression "${elevation} dnf localinstall -y /tmp/chrome/google-chrome-stable_current_x86_64.rpm"

writeLog "Add Microsoft Keys for VS Code"
executeExpression "${elevation} rpm --import https://packages.microsoft.com/keys/microsoft.asc"

writeLog "Always overwrite to ensure the script config is being used"; echo
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

writeLog "Always overwrite to ensure the script config is being used"; echo
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

writeLog "Buildah & Podman"
executeExpression "${elevation} yum install -y podman-docker"
executeExpression "${elevation} touch /etc/containers/nodocker"

writeLog "Terraform for KOT, align with cdaf/linux image"
executeExpression "curl --silent -l https://releases.hashicorp.com/terraform/1.2.2/terraform_1.2.2_linux_amd64.zip --output terraform.zip"
executeExpression "unzip terraform.zip"

executeExpression "${elevation} mv -f terraform /usr/bin/"
executeExpression "terraform --version"

writeLog "Office 365 support in Evolution"
executeExpression "${elevation} yum install -y evolution evolution-ews"

writeLog "Test Buildah & Podman"
executeExpression "docker run -t docker.io/cdaf/linux terraform --version"

writeLog "Helm & Helmsman"
executeExpression "${elevation} snap install helm --classic"

executeExpression "curl -L https://github.com/Praqma/helmsman/releases/download/v3.11.0/helmsman_3.11.0_linux_amd64.tar.gz | tar zx"
executeExpression "${elevation} mv helmsman /usr/sbin"
executeExpression "helmsman"

writeLog "VirtualBox for Vagrant"
executeExpression "${elevation} dnf -y install wget"
executeExpression "wget https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo"
executeExpression "${elevation} mv virtualbox.repo /etc/yum.repos.d/"

executeExpression "wget -q https://www.virtualbox.org/download/oracle_vbox.asc"
executeExpression "${elevation} rpm --import oracle_vbox.asc"

executeExpression "${elevation} dnf -y install binutils kernel-devel kernel-headers libgomp make patch gcc glibc-headers glibc-devel dkms"
executeExpression "${elevation} dnf install -y VirtualBox-6.0"

executeExpression "${elevation} usermod -aG vboxusers $USER"

writeLog "--- end ---"
exit 0
