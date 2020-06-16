#!/usr/bin/env bash

function executeRetry {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval "$1"
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		else
			success='yes'
		fi
	done
}  

scriptName='InstallApacheReverseProxy.sh'

echo "[$scriptName] --- start ---"
context="$1"
if [ -z "$context" ]; then
	echo "[$scriptName]   context      : (not supplied)"
else
	echo "[$scriptName]   context      : $context"
fi

proxyRule="$2"
if [ -z "$proxyRule" ]; then
	echo "[$scriptName]   proxyRule    : (not supplied)"
else
	echo "[$scriptName]   proxyRule    : $proxyRule"
fi

mediaPath="$3"
if [ -z "$mediaPath" ]; then
	mediaPath='/.provision'
	echo "[$scriptName]   mediaPath    : $mediaPath (default)"
else
	echo "[$scriptName]   mediaPath    : $mediaPath"
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

if [ "$centos" ]; then

	echo
	echo "[$scriptName] Install Apache HTTP daemon and modules"
	executeRetry "sudo yum -y install httpd mod_ssl mod_proxy"
	echo
	echo "[$scriptName] Allow persistent (-P) loopback access"
	executeRetry "sudo /usr/sbin/setsebool -P httpd_can_network_connect 1"

	# Only create rules if supplied
	if [ -n "$context" ]; then
		echo
		echo "[$scriptName] Enable mod_proxy and insert supplied proxy rule into /etc/httpd/conf.d/ssl.conf"
		sudo sh -c "echo \"LoadModule proxy_module modules/mod_proxy.so\" >> /etc/httpd/conf.d/ssl.conf"
		sudo sh -c "echo \"<IfModule mod_proxy.c>\" >> /etc/httpd/conf.d/ssl.conf"
		sudo sh -c "echo \"        ProxyPass $context $proxyRule\" >> /etc/httpd/conf.d/ssl.conf"
		sudo sh -c "echo \"        ProxyPassReverse $context $proxyRule\" >> /etc/httpd/conf.d/ssl.conf"
		sudo sh -c "echo \"</IfModule>\" >> /etc/httpd/conf.d/ssl.conf"
		echo
		sudo cat /etc/httpd/conf.d/ssl.conf | egrep -v "(^#.*|^$)"
	fi

	# If certificate files provided, replace the defaults
	if [ -f "$mediaPath/localhost.crt" ]; then
		echo
		echo "[$scriptName] Public Certificate found in mediaPath, replacing ..."
		executeRetry "sudo mv /etc/pki/tls/certs/localhost.crt /etc/pki/tls/certs/localhost.crt.default"
		executeRetry "sudo cp $mediaPath/localhost.crt /etc/pki/tls/certs/localhost.crt"
	fi				
	if [ -f "$mediaPath/localhost.key" ]; then
		echo
		echo "[$scriptName] Private key found in mediaPath, replacing ..."
		executeRetry "sudo mv /etc/pki/tls/private/localhost.key /etc/pki/tls/private/localhost.key.default"
		executeRetry "sudo cp $mediaPath/localhost.key /etc/pki/tls/private/localhost.key"
	fi				
	echo
	echo "[$scriptName] Start the server"
	executeRetry "sudo systemctl start httpd"

else
	echo "[$scriptName] TODO: Debian not supported"
fi
echo
echo "[$scriptName] --- end ---"
