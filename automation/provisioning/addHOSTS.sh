#!/usr/bin/env bash

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='addHOSTS.sh'

echo "[$scriptName] : --- start ---"
ip=$1
if [ -z "$ip" ]; then
	echo "[$scriptName]   ip not supplied!"; exit 110
else
	echo "[$scriptName]   ip       : $ip"
fi

hostname=$2
if [ -z "$hostname" ]; then
	echo "[$scriptName]   hostname not supplied!"; exit 120
else
	echo "[$scriptName]   hostname : $hostname"
fi

if [ "$(whoami)" != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami   : $(whoami)"
else
	echo "[$scriptName]   whoami   : $(whoami) (elevation not required)"
fi

hostsFile='/etc/hosts'
echo "[$scriptName] Read HOSTS to memory then clear the file"
fileInMemory=$(cat ${hostsFile}) # cat will read all lines, native READ will miss lines that don't have line-feed
executeExpression "$elevate truncate -s 0 $hostsFile"

while read -r line; do

    if [[ $line =~ $hostname ]]; then
    	if [[ $elevate == 'sudo' ]]; then
			echo "  sudo sh -c \"echo \"$ip $hostname\" >> /etc/hosts\""
			sudo sh -c "echo \"$ip $hostname\" >> /etc/hosts"
		else
			echo "  sh -c \"echo \"$ip $hostname\" >> /etc/hosts\""
			sh -c "echo \"$ip $hostname\" >> /etc/hosts"
		fi
		replaced='yes'
    else
    	if [[ $elevate == 'sudo' ]]; then
			echo "  sudo sh -c \"echo \"$line\" >> /etc/hosts\""
			sudo sh -c "echo \"$line\" >> /etc/hosts"
		else
			echo "  sh -c \"echo \"$line\" >> /etc/hosts\""
			sh -c "echo \"$line\" >> /etc/hosts"
		fi
    fi

done < <(echo "$fileInMemory")
 
if [[ ! $replaced == 'yes' ]]; then
   	if [[ $elevate == 'sudo' ]]; then
		echo "  sudo sh -c \"echo \"$ip $hostname\" >> /etc/hosts\""
		sudo sh -c "echo \"$ip $hostname\" >> /etc/hosts"
   	else
		echo "  sh -c \"echo \"$ip $hostname\" >> /etc/hosts\""
		sh -c "echo \"$ip $hostname\" >> /etc/hosts"
   	fi
fi
	
echo "[$scriptName] : --- end ---"
