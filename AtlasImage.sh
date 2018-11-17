#!/usr/bin/env bash
scriptName='AtlasImage.sh'
imageLog='/VagrantBox.txt'

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

function executeIgnore {
	writeLog "$1"
	eval $1
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		writeLog "$0 : Warning! $EXECUTABLESCRIPT returned $exitCode"
	fi
}  

scriptName='AtlasImage.sh'
echo; writeLog "Generic provisioning for Linux"
echo; writeLog "--- start ---"
hypervisor=$1
if [ -n "$hypervisor" ]; then
	if [ "$hypervisor" == 'virtualbox' ]; then
		vbadd='5.2.22'
		writeLog "  hypervisor   : $hypervisor (installing extension version ${vbadd})"
	else
		writeLog "  hypervisor   : $hypervisor"
	fi
else
	writeLog "  hypervisor   : (not passed, extension install will not be attempted)"
fi

if [[ $(whoami) != 'vagrant' ]];then
	writeLog "  HALT! Do Not Run as Root or any user other than vagrant, this will apply incorrect permission"; exit 773
else
	elevate='sudo'
	writeLog "  whoami       : $(whoami)"
fi

writeLog "As Vagrant user, trust the public key"
if [ -d "$HOME/.ssh" ]; then
	writeLog "Directory $HOME/.ssh already exists"
else
	executeExpression "mkdir $HOME/.ssh"
fi
executeExpression "chmod 0700 $HOME/.ssh"
executeExpression "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ==' > $HOME/.ssh/authorized_keys"
executeExpression "chmod 0600 $HOME/.ssh/authorized_keys"

test=$(sudo cat /etc/ssh/sshd_config | grep UseDNS)
if [ "$test" ]; then
writeLog "Configuration tweek already applied"
else
	writeLog "Configuration tweek"
	writeLog "  sudo sh -c 'echo \"UseDNS no\" >> /etc/ssh/sshd_config'"
	sudo sh -c 'echo "UseDNS no" >> /etc/ssh/sshd_config'
fi
executeExpression "sudo cat /etc/ssh/sshd_config | grep Use"

test=$(sudo cat /etc/sudoers | grep vagrant)
if [ "$test" ]; then
	writeLog "Vagrant sudo permissions already set"
else
	writeLog "Permission for Vagrant to perform provisioning"
	writeLog "  sudo sh -c 'echo \"vagrant ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'"
	sudo sh -c 'echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
fi
executeExpression "sudo cat /etc/sudoers | grep PASS"

test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	ubuntu=$(uname -a | grep ubuntu)
	if [ "$ubuntu" ]; then
		writeLog "  Debian based : $(uname -mrs)"
	else
		writeLog "  $(uname -a), Unknown distributation, exiting!"; exit 883
	fi
else
	centos=$(cat /etc/redhat-release | grep CentOS)
	if [ -z "$centos" ]; then
		echo "[$scriptName] Red Hat Enterprise Linux"
		rhel='yes'
	else
		echo "[$scriptName] CentOS Linux"
	fi
fi

if [ "$hypervisor" == 'hyperv' ]; then
	if [ "$centos" ]; then
		executeExpression "$elevate yum update -y"
		sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
		executeExpression "$elevate cat /etc/sudoers"
	   	executeExpression "$elevate yum install -y hyperv-daemons cifs-utils"
		executeExpression "$elevate systemctl daemon-reload"
		executeExpression "$elevate systemctl enable hypervkvpd"
	else # Ubuntu, from https://oitibs.com/hyper-v-lis-on-ubuntu-16/
		echo;writeLog "Ubuntu extensions are included (from 12.04), but require activation, list before and after"
		executeExpression "$elevate cat /etc/initramfs-tools/modules"
		echo
		executeExpression '$elevate sh -c "echo \"hv_vmbus\" >> /etc/initramfs-tools/modules"'
		executeExpression '$elevate sh -c "echo \"hv_storvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression '$elevate sh -c "echo \"hv_blkvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression '$elevate sh -c "echo \"hv_netvsc\" >> /etc/initramfs-tools/modules"'
		echo
		executeExpression "$elevate cat /etc/initramfs-tools/modules"
		echo
		executeExpression "$elevate apt-get upgrade -y"
		executeExpression "$elevate apt-get install -y --install-recommends linux-cloud-tools-$(uname -r)"
		executeExpression "$elevate update-initramfs -u"
	fi
else
	if [ "$hypervisor" == 'virtualbox' ]; then
		if [ "$centos" ]; then
			echo;writeLog "Install prerequisites"
			executeExpression "$elevate yum update -y"
			sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
			executeExpression "$elevate cat /etc/sudoers"
			executeExpression "$elevate yum groupinstall -y 'Development Tools'"
			if [ "$rhel" ]; then # Use named for Red Hat
				executeExpression "$elevate yum install -y gcc kernel-devel-$(uname -r) kernel-headers dkms make bzip2 perl
			else
				executeExpression "$elevate yum install -y gcc kernel-devel kernel-headers dkms make bzip2 perl"
			fi
			executeExpression "KERN_DIR=/usr/src/kernels/$(uname -r)"
			executeExpression "export KERN_DIR"
		
		else # Ubuntu
			echo;writeLog "Install prerequisites"
			executeExpression "$elevate apt-get upgrade -y"
			executeExpression "$elevate apt-get install -y linux-headers-$(uname -r) build-essential dkms"
		fi
		echo;writeLog "Download and install VirtualBox extensions version $vbadd"; echo
		executeExpression "curl -O http://download.virtualbox.org/virtualbox/${vbadd}/VBoxGuestAdditions_${vbadd}.iso"
		executeExpression "$elevate mkdir /media/VBoxGuestAdditions"
		executeExpression "$elevate mount -o loop,ro VBoxGuestAdditions_${vbadd}.iso /media/VBoxGuestAdditions"
			
		# This is normal for server install ...
		#    Could not find the X.Org or XFree86 Window System, skipping.
		executeIgnore "$elevate sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run"
		executeExpression "rm VBoxGuestAdditions_${vbadd}.iso"
		executeExpression "$elevate umount /media/VBoxGuestAdditions"
		executeExpression "$elevate rmdir /media/VBoxGuestAdditions"
	fi
fi

if [ "$centos" ]; then
	writeLog "Cleanup"
	executeExpression "$elevate yum clean all"
	executeExpression "$elevate rm -rf /var/cache/yum"
	executeExpression "$elevate rm -rf /tmp/*"
	executeExpression "$elevate rm -f /var/log/wtmp /var/log/btmp"
	executeIgnore "$elevate dd if=/dev/zero of=/EMPTY bs=1M"
	executeExpression "$elevate rm -f /EMPTY"
	executeExpression "$elevate sync"
	executeExpression "history -c"
else # Ubuntu
	executeExpression "$elevate apt-get autoremove && $elevate apt-get clean && $elevate apt-get autoclean" 
	executeExpression "$elevate rm -r /var/log/*"
	executeExpression "$elevate telinit 1"
	executeExpression "$elevate mount -o remount,ro /dev/sda1"
	executeExpression "$elevate zerofree -v /dev/sda1" 
fi

writeLog "Image complete, shutdown VM"
executeExpression "$elevate shutdown -h now"

writeLog "--- end ---"
exit 0
