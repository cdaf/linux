#!/usr/bin/env bash
scriptName='addHOSTS.sh'

echo "[$scriptName] : --- start ---"
if [ -z "$1" ]; then
	ip='172.16.17.102'
	echo "[$scriptName]   ip       : $ip (default)"
else
	ip=$1
	echo "[$scriptName]   ip       : $ip"
fi

if [ -z "$2" ]; then
	hostname='app.skynet'
	echo "[$scriptName]   hostname : $hostname (default)"
else
	hostname=$2
	echo "[$scriptName]   hostname : $hostname"
fi

# Use hosts entries to provide DNS within the closed network
echo "Add app.skynet and buildserver.skynet to each others hosts file"
sudo sh -c "echo \"$ip $hostname\" >> /etc/hosts"
 
echo "[$scriptName] : --- end ---"
