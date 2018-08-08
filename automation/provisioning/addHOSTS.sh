#!/usr/bin/env bash
scriptName='addHOSTS.sh'

echo "[$scriptName] : --- start ---"
ip=$1
if [ -z "$ip" ]; then
	echo "[$scriptName]   ip not supplied!"; exit 110
else
	echo "[$scriptName]   ip       : $ip"
fi

hostname=$2
if [ -z "hostname" ]; then
	echo "[$scriptName]   hostname not supplied!"; exit 120
else
	echo "[$scriptName]   hostname : $hostname"
fi

echo "Use hosts entries to provide DNS override"
echo "  sudo sh -c \"echo \"$ip $hostname\" >> /etc/hosts\""
sudo sh -c "echo \"$ip $hostname\" >> /etc/hosts"
 
echo "[$scriptName] : --- end ---"
