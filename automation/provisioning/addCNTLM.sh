#!/usr/bin/env bash
scriptName='addCNTLM.sh'

echo; echo "[$scriptName] User following to mask password"
echo "[$scriptName] read -s password"
echo "[$scriptName] Example call"
echo "[$scriptName] ./addCNTLM.sh username DOMAIN proxyserver.example.com:port $password"; echo
echo "[$scriptName] : --- start ---"
if [ -z "$1" ]; then
	echo "[$scriptName]   username not supplied, exiting with code 101!"
	exit 101
else
	username=$1
	echo "[$scriptName]   username : $username"
fi

if [ -z "$2" ]; then
	echo "[$scriptName]   domain not supplied, exiting with code 102!"
	exit 102
else
	domain=$2
	echo "[$scriptName]   domain   : $domain"
fi

if [ -z "$3" ]; then
	echo "[$scriptName]   proxy not supplied, exiting with code 103!"
	exit 103
else
	proxy=$3
	echo "[$scriptName]   proxy    : $proxy"
fi

if [ -z "$4" ]; then
	echo "[$scriptName]   password not supplied, exiting with code 104!"
	exit 104
else
	password=$4
	echo "[$scriptName]   password : ********"
fi

if [ -z "$5" ]; then
	media='.provision'
	echo "[$scriptName]   media    : $media (default)"
else
	media=$5
	echo "[$scriptName]   media    : $media"
fi

echo 'Determine the RPM name from the media directory'
rpm=$(ls -1 "$media/cntlm*.rpm")
sudo rpm -i "$rpm"

echo 'Load settings and list configuration settings'
sudo sh -c "echo \"Username        $username\" > /etc/cntlm.conf"
sudo sh -c "echo \"Domain          $domain\" >> /etc/cntlm.conf"
sudo sh -c "echo \"Proxy           $proxy\" >> /etc/cntlm.conf"

# Do not use proxy for local traffic, nor reserved Class A, B or C ranges
sudo sh -c "echo \"NoProxy         localhost, 127.0.0.*, 10.*, 172.16.*, 192.168.*\" >> /etc/cntlm.conf"
sudo sh -c "echo \"Listen          3128\" >> /etc/cntlm.conf"

# Generate hash using password supplied against and arbitrary address
#hashLine=$(sudo cntlm -H -M http://www.google.com | grep PassNTLMv2)
#sudo sh -c "echo \"$hashLine\" >> /etc/cntlm.conf"

cat /etc/cntlm.conf

echo "[$scriptName] : --- end ---"
