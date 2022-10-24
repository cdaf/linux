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
		if [ -z $2 ]; then
			writeLog "$0 : Warning! $EXECUTABLESCRIPT returned $exitCode"
		else
			if [ "$exitCode" == "$2" ]; then
				writeLog "$0 : Warning! $EXECUTABLESCRIPT returned non-zero exit code ${exitCode} but is ignored due to $2 passed as ignored exit code"
				writeLog "cat /var/log/vboxadd-setup.log"
				cat /var/log/vboxadd-setup.log
			else
				writeLog "$0 : ERROR! $EXECUTABLESCRIPT returned non-zero exit code ${exitCode} and is exiting becuase ignored exist code is $2"
				exit $exitCode
			fi
		fi
	fi
}  

function installVBox {
	curlOpt="$1"
	vbadd="$2"
	echo;writeLog "Download and install VirtualBox Guest Additions version $vbadd"; echo
	executeExpression "curl $curlOpt --silent -O http://download.virtualbox.org/virtualbox/${vbadd}/VBoxGuestAdditions_${vbadd}.iso"

	if [ -d "/media/VBoxGuestAdditions" ]; then
		writeLog "sudo umount /media/VBoxGuestAdditions"
		sudo umount /media/VBoxGuestAdditions
		executeExpression "sudo rmdir /media/VBoxGuestAdditions"
	fi

	executeExpression "sudo mkdir /media/VBoxGuestAdditions"
	executeExpression "sudo mount -o loop,ro VBoxGuestAdditions_${vbadd}.iso /media/VBoxGuestAdditions"

	echo;writeLog "This is normal for server install ..."
	writeLog "  Could not find the X.Org or XFree86 Window System, skipping."; echo
	if [ -z "$3" ]; then
		executeExpression "sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run"
	else
		executeIgnore "sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run" $3
	fi
	executeExpression "rm VBoxGuestAdditions_${vbadd}.iso"
	executeExpression "sudo umount /media/VBoxGuestAdditions"
	executeExpression "sudo rmdir /media/VBoxGuestAdditions"
	echo;writeLog "Clean-up prerequisites"
}

echo; writeLog "--- start ---"
hypervisor=$1
if [ ! -z "$hypervisor" ]; then
	if [ "$hypervisor" == 'virtualbox' ]; then
		if [ -z "$3" ]; then
			vbadd='6.1.40'
			writeLog "  hypervisor   : $hypervisor (installing default extension version ${vbadd})"
		else
			vbadd="$3"
			writeLog "  hypervisor   : $hypervisor (installing extension version ${vbadd})"
		fi
	else
		writeLog "  hypervisor   : $hypervisor"
	fi

	haltonaddon=$2
	if [ -z "$haltonaddon" ]; then
		haltonaddon='proceed'
		writeLog "  haltonaddon  : $haltonaddon (default)"
	else
		writeLog "  haltonaddon  : $haltonaddon (halt if installVBox fails)"
	fi
else
	writeLog "  hypervisor   : (not passed, extension install will not be attempted)"
fi

if [[ $(whoami) != 'vagrant' ]];then
	writeLog "  HALT! Do Not Run as Root or any user other than vagrant, this will apply incorrect permision"; exit 773
else
	writeLog "  whoami       : $(whoami)"
fi

if [ ! -z "$HTTP_PROXY" ]; then
	writeLog "  HTTP_PROXY   : $HTTP_PROXY"
	curlOpt="-x $HTTP_PROXY"
else
	writeLog "  HTTP_PROXY   : (not set)"
fi

if [ -f '/etc/centos-release' ]; then
	distro=$(cat /etc/centos-release)
	echo "[$scriptName]   distro   : $distro"
	fedora='yes'
else
	if [ -f '/etc/redhat-release' ]; then
		distro=$(cat /etc/redhat-release)
		echo "[$scriptName]   distro   : $distro"
		fedora='yes'
	else
		debian='yes'
		test=$(lsb_release --all 2>&1)
		if [[ "$test" == *"not found"* ]]; then
			if [ -f "/etc/issue" ]; then
				distro=$(cat "/etc/issue")
				echo "[$scriptName]   distro   : $distro"
			else
				distro=$(uname -a)
				echo "[$scriptName]   distro   : $distro"
			fi
		else
			while IFS= read -r line; do
				if [[ "$line" == *"Description"* ]]; then
					IFS=' ' read -ra ADDR <<< $line
					distro=$(echo "${ADDR[1]} ${ADDR[2]}")
					echo "[$scriptName]   distro   : $distro"
				fi
			done <<< "$test"
			if [ -z "$distro" ]; then
				writeLog "  HALT! Unable to determine distribution!"; exit 774
			fi
		fi	
	fi
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

echo;writeLog "Perform provider independent steps"
if [ "$fedora" ]; then

	# https://medium.com/@gevorggalstyan/creating-own-custom-vagrant-box-ae7e94043a4e
	echo;writeLog "Remove additional packages"
	executeIgnore "sudo systemctl stop postfix"
	executeIgnore "sudo systemctl disable postfix"
	executeIgnore "sudo yum -y remove postfix"
	executeIgnore "sudo systemctl stop chronyd"
	executeIgnore "sudo systemctl disable chronyd"
	executeIgnore "sudo yum -y remove chrony"
	executeIgnore "sudo systemctl stop avahi-daemon.socket avahi-daemon.service"
	executeIgnore "sudo systemctl disable avahi-daemon.socket avahi-daemon.service"
	executeIgnore "sudo yum -y remove avahi-autoipd avahi-libs avahi"
	executeExpression "sudo service network restart"
	executeExpression "sudo chkconfig network on"
	executeExpression "sudo systemctl restart network"

	echo;writeLog "Upgrade System"
	executeExpression "sudo yum update -y"

	echo;writeLog "Set configuration to not require tty"
	writeLog "  sudo sh -c 'sed -i \"s/^\(Defaults.*requiretty\)/#\1/\" /etc/sudoers'"
	sudo sh -c 'sed -i "s/^\(Defaults.*requiretty\)/#\1/" /etc/sudoers'
	writeLog "  sudo sh -c 'echo \"Defaults !requiretty\" >> /etc/sudoers'"
	sudo sh -c 'echo "Defaults !requiretty" >> /etc/sudoers'
	executeExpression "sudo cat /etc/sudoers"

else # Ubuntu

	# Disable IPv6, which stops default gateway in Ubuntu 22.10
	echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf
	echo "net.ipv6.conf.default.disable_ipv6=1" | sudo tee -a /etc/sysctl.conf
	echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
	executeExpression "sudo sysctl -p"

    # disable auto updates introduced in 18.04
	if [ -f "/etc/apt/apt.conf.d/20auto-upgrades" ]; then
		if [ ! -z "$(cat "/etc/apt/apt.conf.d/20auto-upgrades" | grep 1)" ]; then
			executeExpression "cat /etc/apt/apt.conf.d/20auto-upgrades"
			token='APT::Periodic::Update-Package-Lists \"1\";'
			value='APT::Periodic::Update-Package-Lists \"0\";'
			executeExpression "sudo sed -i -- \"s^$token^$value^g\" /etc/apt/apt.conf.d/20auto-upgrades"
			token='APT::Periodic::Unattended-Upgrade \"1\";'
			value='APT::Periodic::Unattended-Upgrade \"0\";'
			executeExpression "sudo sed -i -- \"s^$token^$value^g\" /etc/apt/apt.conf.d/20auto-upgrades"
			executeExpression "cat /etc/apt/apt.conf.d/20auto-upgrades"
			aptLockRelease
		fi
		executeExpression "sudo apt remove -y unattended-upgrades"
	fi
	executeExpression "sudo apt-get update"
	executeExpression "sudo apt-get upgrade -y"
fi

echo;writeLog "Perform provider specific steps"
if [ "$hypervisor" == 'hyperv' ]; then
	if [ "$fedora" ]; then
	   	executeExpression "sudo yum install -y hyperv-daemons cifs-utils"
		executeExpression "sudo systemctl daemon-reload"
		executeExpression "sudo systemctl enable hypervkvpd"
	else # Ubuntu
		echo;writeLog "Based on https://oitibs.com/hyper-v-lis-on-ubuntu-18-04/"
		writeLog "Ubuntu extensions are included (from 12.04), but require activation, list before and after"
		executeExpression "sudo cat /etc/initramfs-tools/modules"
		echo
		executeExpression 'sudo sh -c "echo \"hv_vmbus\" >> /etc/initramfs-tools/modules"'
		executeExpression 'sudo sh -c "echo \"hv_storvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression 'sudo sh -c "echo \"hv_blkvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression 'sudo sh -c "echo \"hv_netvsc\" >> /etc/initramfs-tools/modules"'
		echo
		executeExpression "sudo cat /etc/initramfs-tools/modules"			
		echo
		executeExpression "sudo apt-get install -y --install-recommends linux-virtual linux-cloud-tools-virtual linux-tools-virtual cifs-utils"
		executeExpression "sudo update-initramfs -u"
	fi
else # VitualBox
	if [ "$hypervisor" == 'virtualbox' ]; then
		echo;writeLog "Install VirtualBox Guest Additions"
		if [ "$fedora" ]; then
			executeExpression "sudo yum groupinstall -y 'Development Tools'"
			executeExpression "sudo yum install -y gcc dkms make bzip2 perl"
			executeExpression "sudo yum install -y kernel-devel-$(uname -r)"
			executeExpression "sudo yum install -y kernel-headers"
			executeExpression "KERN_DIR=/usr/src/kernels/$(uname -r)"
			executeExpression "export KERN_DIR"
			executeExpression "ls $KERN_DIR"

			installVBox "$curlOpt" "$vbadd"

			executeExpression "sudo yum remove -y kernel-headers"
			executeExpression "sudo yum remove -y kernel-devel-$(uname -r)"
			executeExpression "sudo yum remove -y gcc dkms make bzip2 perl"
			executeExpression "sudo yum groupremove -y 'Development Tools'"
		else # Ubuntu
			if [[ "$distro" == *"16.04"* ]]; then
				writeLog "Distro is ${distro}, install canonical VirtualBox Guest Additions"
				executeExpression "sudo apt-get install -y virtualbox-guest-dkms"
			else
				# Canonical does not work, using https://www.tecmint.com/install-virtualbox-guest-additions-in-ubuntu/ as guide
				writeLog "Distro is ${distro}, install latest VirtualBox Guest Additions"
				executeExpression "sudo apt install -y build-essential dkms linux-headers-$(uname -r)"
				if [[ "$haltonaddon" == 'proceed' ]]; then
					installVBox "$curlOpt" "$vbadd" 2 # ignore exit code 2 when installing additions
				else
					installVBox "$curlOpt" "$vbadd" # halt on error
				fi
			fi
		fi
	fi
fi

writeLog "Cleanup"
if [ "$fedora" ]; then
	# https://medium.com/@gevorggalstyan/creating-own-custom-vagrant-box-ae7e94043a4e
	executeExpression "sudo yum -y install yum-utils"
	executeExpression "sudo package-cleanup -y --oldkernels --count=1"
	executeExpression "sudo yum -y autoremove"
	executeExpression "sudo yum -y remove yum-utils"

	executeExpression "sudo yum clean all"
	executeExpression "sudo rm -rf /var/cache/yum"
	executeExpression "sudo rm -rf /tmp/*"
	executeExpression "sudo rm -f /var/log/wtmp /var/log/btmp"
	executeIgnore "sudo dd if=/dev/zero of=/EMPTY bs=1M"
	executeExpression "sudo rm -f /EMPTY"
	executeExpression "sudo sync"
	executeExpression "cat /dev/null > ~/.bash_history"
	executeExpression "history -c"
else # Ubuntu
	executeExpression "sudo apt-get autoremove" 
	executeExpression "sudo apt-get clean" 
	executeExpression "sudo apt-get autoclean" 
	executeExpression "sudo rm -r /var/log/*"
	executeExpression "sudo telinit 1"
	if [[ "$distro" == *"16.04"* ]]; then
		executeExpression "sudo mount -o remount,ro /dev/sda1"
		executeExpression "sudo zerofree -v /dev/sda1"
	else # use the same method as fedora, based on https://unix.stackexchange.com/questions/499631/how-to-use-zerofree-on-a-whole-disk
		executeIgnore "sudo dd if=/dev/zero of=/EMPTY bs=1M"
		executeExpression "sudo rm -f /EMPTY"
	fi
fi

writeLog "Image complete, shutdown VM"
executeExpression "sudo shutdown -h now"

writeLog "--- end ---"
exit 0
