#!/usr/bin/env bash
imageLog='/VagrantBox.txt'
scriptName='AtlasBase.sh'

function writeLog {
	echo "[$scriptName][$(date)] $1"
	sudo sh -c "echo '[$scriptName] $1' >> $imageLog"
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

echo; writeLog "[$scriptName] Generic provisioning for Linux"
echo; writeLog "[$scriptName] --- start ---"
centos=$(uname -mrs | grep .el)
if [ "$centos" ]; then
	writeLog "[$scriptName]   Fedora based : $(uname -mrs)"
else
	ubuntu=$(uname -a | grep ubuntu)
	if [ "$ubuntu" ]; then
		writeLog "[$scriptName]   Debian based : $(uname -mrs)"
	else
		writeLog "[$scriptName]   $(uname -a), proceeding assuming Debian based..."; echo
	fi
fi

writeLog "[$scriptName] As Vagrant user, trust the public key"
if [ -d "$HOME/.ssh" ]; then
	writeLog "[$scriptName] Directory $HOME/.ssh already exists"
else
	executeExpression "mkdir $HOME/.ssh"
fi
executeExpression "chmod 0700 $HOME/.ssh"
executeExpression "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ==' > $HOME/.ssh/authorized_keys"
executeExpression "chmod 0600 $HOME/.ssh/authorized_keys"

writeLog "[$scriptName] Configuration tweek"
test=$(sudo cat /etc/ssh/sshd_config | grep UseDNS)
if [ "$test" ]; then
	writeLog "[$scriptName] Vagrant sudo permissions set"
else
	writeLog "[$scriptName]  sudo sh -c 'echo \"UseDNS no\" >> /etc/ssh/sshd_config'"
	sudo sh -c "echo 'UseDNS no' >> /etc/ssh/sshd_config"
fi
executeExpression "sudo cat /etc/ssh/sshd_config | grep Use"

test=$(sudo cat /etc/sudoers | grep vagrant)
if [ "$test" ]; then
	writeLog "[$scriptName] Vagrant sudo permissions set"
else
	writeLog "[$scriptName] Permission for Vagrant to perform provisioning"
	writeLog "[$scriptName]  sudo sh -c 'echo \"vagrant ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers\"'"
	sudo sh -c "echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
fi
executeExpression "sudo cat /etc/sudoers | grep PASS"

writeLog "[$scriptName] --- end ---"
exit 0
