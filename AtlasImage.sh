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
	writeLog "  whoami       : $(whoami)"
fi

if [ "$hypervisor" == 'virtualbox' ]; then
	echo;writeLog "Download and install VirtualBox extensions version $vbadd"; echo
	executeExpression "curl -O http://download.virtualbox.org/virtualbox/${vbadd}/VBoxGuestAdditions_${vbadd}.iso"
	executeExpression "sudo mkdir /media/VBoxGuestAdditions"
	executeExpression "sudo mount -o loop,ro VBoxGuestAdditions_${vbadd}.iso /media/VBoxGuestAdditions"
		
	# This is normal for server install ...
	#    Could not find the X.Org or XFree86 Window System, skipping.
	executeIgnore "sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run"
	executeExpression "rm VBoxGuestAdditions_${vbadd}.iso"
	executeExpression "sudo umount /media/VBoxGuestAdditions"
	executeExpression "sudo rmdir /media/VBoxGuestAdditions"
fi

if [ "$centos" ]; then
	writeLog "Cleanup"
	executeExpression "sudo yum clean all"
	executeExpression "sudo rm -rf /var/cache/yum"
	executeExpression "sudo rm -rf /tmp/*"
	executeExpression "sudo rm -f /var/log/wtmp /var/log/btmp"
	executeIgnore "sudo dd if=/dev/zero of=/EMPTY bs=1M"
	executeExpression "sudo rm -f /EMPTY"
	executeExpression "sudo sync"
	executeExpression "history -c"
else # Ubuntu
	executeExpression "sudo apt-get autoremove && sudo apt-get clean && sudo apt-get autoclean" 
	executeExpression "sudo rm -r /var/log/*"
	executeExpression "sudo telinit 1"
	executeExpression "sudo mount -o remount,ro /dev/sda1"
	executeExpression "sudo zerofree -v /dev/sda1" 
fi

writeLog "Image complete, shutdown VM"
executeExpression "sudo shutdown -h now"

writeLog "--- end ---"
exit 0
