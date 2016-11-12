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

scriptName='InstallApacheReverseProxy.sh'

echo "[$scriptName] --- start ---"
context="$1"
if [ -z "$context" ]; then
	echo "[$scriptName]   context   : (not supplied)"
else
	echo "[$scriptName]   context   : $context"
fi

proxyRule="$2"
if [ -z "$proxyRule" ]; then
	echo "[$scriptName]   proxyRule : (not supplied)"
else
	echo "[$scriptName]   proxyRule : $proxyRule"
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
	echo "[$scriptName] Install Canon"
	executeExpression "sudo yum -y install httpd mod_ssl mod_proxy"

	echo "[$scriptName] Allow persistent (-P) loopback access"
	executeExpression "sudo /usr/sbin/setsebool -P httpd_can_network_connect 1"

	# Only create rules if supplied
	if [ -n "$context" ]; then
		echo "[$scriptName] Enable mod_proxy and insert supplied proxy rule"
		sudo sh -c "echo \"LoadModule proxy_module modules/mod_proxy.so\" >> /etc/httpd/conf.d/ssl.conf"
		sudo sh -c "echo \"<IfModule mod_proxy.c>\" >> /etc/httpd/conf.d/ssl.conf"
		sudo sh -c "echo \"        ProxyPass $context $proxyRule\" >> /etc/httpd/conf.d/ssl.conf"
		sudo sh -c "echo \"        ProxyPassReverse $context $proxyRule\" >> /etc/httpd/conf.d/ssl.conf"
		sudo sh -c "echo \"</IfModule>\" >> /etc/httpd/conf.d/ssl.conf"
		sudo cat /etc/httpd/conf.d/ssl.conf | egrep -v "(^#.*|^$)"
	fi

	echo "[$scriptName] Start the server"
	executeExpression "sudo systemctl start httpd"

else
	echo "[$scriptName] TODO: Debian not supported"
fi

echo "[$scriptName] --- end ---"
