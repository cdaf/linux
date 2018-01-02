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
hypervisor=$1
if [ -n "$hypervisor" ]; then
	echo "[$scriptName]   hypervisor   : $hypervisor"
else
	echo "[$scriptName] hypervisor not passed, exit 1"; exit 1
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami       : $(whoami)"
else
	echo "[$scriptName]   whoami       : $(whoami) (elevation not required)"
fi

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

if [ "$hypervisor" == 'hyperv' ]; then
	if [ "$centos" ]; then
		executeExpression "$elevate yum update -y"
		sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
		executeExpression "$elevate cat /etc/sudoers"
	   	executeExpression "$elevate yum install -y hyperv-daemons cifs-utils"
		executeExpression "$elevate systemctl daemon-reload"
		executeExpression "$elevate systemctl enable hypervkvpd"
else # Ubuntu, from https://oitibs.com/hyper-v-lis-on-ubuntu-16/
		echo;echo "[$scriptName] Ubuntu extensions are included (from 12.04), but require activation, list before and after"
		executeExpression '$elevate cat /etc/initramfs-tools/modules"'
		echo
		executeExpression '$elevate sh -c "echo \"hv_vmbus\" >> /etc/initramfs-tools/modules"'
		executeExpression '$elevate sh -c "echo \"hv_storvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression '$elevate sh -c "echo \"hv_blkvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression '$elevate sh -c "echo \"hv_netvsc\" >> /etc/initramfs-tools/modules"'
		echo
		executeExpression '$elevate cat /etc/initramfs-tools/modules"'
		echo
		executeExpression '$elevate apt-get install -y --install-recommends linux-cloud-tools-$(uname -r)'
		executeExpression '$elevate update-initramfs -u'
	fi
else # VirtualBox
	if [ "$centos" ]; then
		executeExpression "$elevate yum update -y"
		sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
		executeExpression "$elevate cat /etc/sudoers"
		executeExpression "$elevate rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm"
		executeExpression "$elevate yum install -y gcc kernel-devel kernel-headers dkms make bzip2 perl"
		executeExpression "KERN_DIR=/usr/src/kernels/`uname -r`"
		executeExpression "export KERN_DIR"
	
		echo;echo "[$scriptName] Load the Guest Editions using the VirtualBox GUI, Devices --> Insert Guest Editions ISO image"
		executeExpression "$elevate mkdir /media/VirtualBoxGuestAdditions"
		executeExpression "$elevate mount -r /dev/cdrom /media/VirtualBoxGuestAdditions"
		executeExpression "cd /media/VirtualBoxGuestAdditions"
		executeExpression "$elevate ./VBoxLinuxAdditions.run"
	else # Ubuntu
		echo;echo "[$scriptName] Install prerequisites, then Download and install VirtualBox extensions"
		vbadd='5.1.10'
		executeExpression "$elevate apt-get install -y linux-headers-$(uname -r) build-essential dkms"
		executeExpression "wget http://download.virtualbox.org/virtualbox/${vbadd}/VBoxGuestAdditions_${vbadd}.iso"
		executeExpression "$elevate mkdir /media/VBoxGuestAdditions"
		executeExpression "$elevate mount -o loop,ro VBoxGuestAdditions_${vbadd}.iso /media/VBoxGuestAdditions"
			
		# This is normal for server install
		# Could not find the X.Org or XFree86 Window System, skipping.
		executeExpression "$elevate sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run"
		executeExpression "rm VBoxGuestAdditions_${vbadd}.iso"
		executeExpression "$elevate umount /media/VBoxGuestAdditions"
		executeExpression "$elevate rmdir /media/VBoxGuestAdditions"
	fi

fi

if [ "$centos" ]; then
	echo "[$scriptName] Cleanup"
	executeExpression "$elevate yum clean all"
	executeExpression "$elevate rm -rf /tmp/*"
	executeExpression "$elevate rm -f /var/log/wtmp /var/log/btmp"
	executeExpression "$elevate history -c"
	executeExpression "$elevate dd if=/dev/zero of=/EMPTY bs=1M"
	executeExpression "$elevate rm -f /EMPTY"
	executeExpression "$elevate sync"
else # Ubuntu
	executeExpression "$elevate apt-get autoremove && $elevate apt-get clean && $elevate apt-get autoclean" 
	executeExpression "$elevate rm -r /var/log/*"
	executeExpression "$elevate telinit 1"
	executeExpression "$elevate mount -o remount,ro /dev/sda1"
	executeExpression "$elevate zerofree -v /dev/sda1" 
fi

echo "[$scriptName] Image complete, shutdown VM with 1 minute pause"
executeExpression "$elevate shutdown -h 1"

echo "[$scriptName] --- end ---"
exit 0
