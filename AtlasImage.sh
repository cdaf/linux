#!/usr/bin/env bash

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

scriptName='AtlasBase.sh'
echo
echo "[$scriptName] Generic provisioning for Linux"
echo
echo "[$scriptName] --- start ---"
centos=$(uname -mrs | grep .el)
if [ "$centos" ]; then
	echo "[$scriptName]   Fedora based : $(uname -mrs)"
else
	ubuntu=$(uname -a | grep ubuntu)
	if [ "$ubuntu" ]; then
		echo "[$scriptName]   Debian based : $(uname -mrs)"
	else
		echo "[$scriptName]   $(uname -a), proceeding assuming Debian based..."; echo
	fi
fi

hypervisor=$1
if [ -n "$hypervisor" ]; then
	echo "[$scriptName]   hypervisor     : $hypervisor"
else
	echo "[$scriptName] hypervisor not passed, exit 1"; exit 1
fi

if [ "$hypervisor" == 'hyperv' ]; then
	if [ "$centos" ]; then
		executeExpression "yum update -y"
		sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
		executeExpression "cat /etc/sudoers"
	   	executeExpression "yum install -y hyperv-daemons cifs-utils"
		executeExpression "systemctl daemon-reload"
		executeExpression "systemctl enable hypervkvpd"
	else # Ubuntu
		echo;echo "[$scriptName] Ubuntu does not require extensions (from 14.04)"
	fi
else # VirtualBox
	if [ "$centos" ]; then
		executeExpression "sudo yum update -y"
		sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
		executeExpression "cat /etc/sudoers"
		executeExpression "rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm"
		executeExpression "yum install -y gcc kernel-devel kernel-headers dkms make bzip2 perl"
		executeExpression "KERN_DIR=/usr/src/kernels/`uname -r`"
		executeExpression "export KERN_DIR"
	
		echo;echo "[$scriptName] Load the Guest Editions using the VirtualBox GUI, Devices --> Insert Guest Editions ISO image"
		executeExpression "mkdir /media/VirtualBoxGuestAdditions"
		executeExpression "mount -r /dev/cdrom /media/VirtualBoxGuestAdditions"
		executeExpression "cd /media/VirtualBoxGuestAdditions"
		executeExpression "./VBoxLinuxAdditions.run"
	else # Ubuntu
		echo;echo "[$scriptName] Install prerequisites, then Download and install VirtualBox extensions"
		vbadd='5.1.10'
		executeExpression "sudo apt-get install -y linux-headers-$(uname -r) build-essential dkms"
		executeExpression "wget http://download.virtualbox.org/virtualbox/${vbadd}/VBoxGuestAdditions_${vbadd}.iso"
		executeExpression "sudo mkdir /media/VBoxGuestAdditions"
		executeExpression "sudo mount -o loop,ro VBoxGuestAdditions_${vbadd}.iso /media/VBoxGuestAdditions"
			
		# This is normal for server install
		# Could not find the X.Org or XFree86 Window System, skipping.
		executeExpression "sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run"
		executeExpression "rm VBoxGuestAdditions_${vbadd}.iso"
		executeExpression "sudo umount /media/VBoxGuestAdditions"
		executeExpression "sudo rmdir /media/VBoxGuestAdditions"
	fi

fi

if [ "$centos" ]; then
	echo "[$scriptName] Cleanup"
	executeExpression "yum clean all"
	executeExpression "rm -rf /tmp/*"
	executeExpression "rm -f /var/log/wtmp /var/log/btmp"
	executeExpression "history -c"
	executeExpression "dd if=/dev/zero of=/EMPTY bs=1M"
	executeExpression "rm -f /EMPTY"
	executeExpression "sync"
else # Ubuntu
	executeExpression "sudo apt-get autoremove && sudo apt-get clean && sudo apt-get autoclean" 
	executeExpression "sudo rm -r /var/log/*"
	executeExpression "sudo telinit 1"
	executeExpression "sudo mount -o remount,ro /dev/sda1"
	executeExpression "sudo zerofree -v /dev/sda1" 
fi

echo "[$scriptName] Image complete, shutdown VM"
executeExpression "shutdown -h 2"

echo "[$scriptName] --- end ---"
exit 0
