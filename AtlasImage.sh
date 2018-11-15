#!/usr/bin/env bash
scriptName='AtlasImage.sh'
imageLog='/VagrantBox.txt'

function writeLog {
	Write-Host "[$scriptName][$(date)] $1"
	echo "[$scriptName] $1" >> $imageLog
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
	writeLog "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		writeLog "$0 : Warning! $EXECUTABLESCRIPT returned $exitCode"
	fi
}  

scriptName='AtlasImage.sh'
echo; writeLog "[$scriptName] Generic provisioning for Linux"
echo; writeLog "[$scriptName] --- start ---"
hypervisor=$1
if [ -n "$hypervisor" ]; then
	writeLog "[$scriptName]   hypervisor   : $hypervisor"
else
	writeLog "[$scriptName]   hypervisor   : (not passed, extension install will not be attempted)"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	writeLog "[$scriptName]   whoami       : $(whoami)"
else
	writeLog "[$scriptName]   whoami       : $(whoami) (elevation not required)"
fi

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

if [ "$hypervisor" == 'hyperv' ]; then
	if [ "$centos" ]; then
		executeExpression "$elevate yum update -y"
		sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
		executeExpression "$elevate cat /etc/sudoers"
	   	executeExpression "$elevate yum install -y hyperv-daemons cifs-utils"
		executeExpression "$elevate systemctl daemon-reload"
		executeExpression "$elevate systemctl enable hypervkvpd"
else # Ubuntu, from https://oitibs.com/hyper-v-lis-on-ubuntu-16/
		echo;writeLog "[$scriptName] Ubuntu extensions are included (from 12.04), but require activation, list before and after"
		executeExpression "$elevate cat /etc/initramfs-tools/modules"
		echo
		executeExpression '$elevate sh -c "echo \"hv_vmbus\" >> /etc/initramfs-tools/modules"'
		executeExpression '$elevate sh -c "echo \"hv_storvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression '$elevate sh -c "echo \"hv_blkvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression '$elevate sh -c "echo \"hv_netvsc\" >> /etc/initramfs-tools/modules"'
		echo
		executeExpression "$elevate cat /etc/initramfs-tools/modules"
		echo
		executeExpression "$elevate apt-get install -y --install-recommends linux-cloud-tools-$(uname -r)"
		executeExpression "$elevate update-initramfs -u"
	fi
else
	if [ "$hypervisor" == 'virtualbox' ]; then
		if [ "$centos" ]; then
			echo;writeLog "[$scriptName] Install prerequisites"
			executeExpression "$elevate yum update -y"
			sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
			executeExpression "$elevate cat /etc/sudoers"
			executeExpression "$elevate yum groupinstall -y 'Development Tools'"
			executeExpression "$elevate yum install -y gcc kernel-devel kernel-headers dkms make bzip2 perl"
			executeExpression "KERN_DIR=/usr/src/kernels/`uname -r`"
			executeExpression "export KERN_DIR"
		
		else # Ubuntu
			echo;writeLog "[$scriptName] Install prerequisites"
			executeExpression "$elevate apt-get install -y linux-headers-$(uname -r) build-essential dkms"
		fi
		vbadd='5.1.10'
		echo;writeLog "[$scriptName] Download and install VirtualBox extensions version $vbadd"; echo
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
	writeLog "[$scriptName] Cleanup"
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

writeLog "[$scriptName] Image complete, shutdown VM"
executeExpression "$elevate shutdown -h now"

writeLog "[$scriptName] --- end ---"
exit 0
