#!/usr/bin/env bash

# Install latest version
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/installApacheMaven.sh | bash -

# Install specific version
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/installApacheMaven.sh | bash -s -- '3.9.14'

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
scriptName='installApacheMaven.sh'

echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version=$(curl -s https://maven.apache.org/download.cgi | grep '<h2>Apache Maven')
	version=${version//'<h2>Apache Maven '/}
	version=${version//'</h2>'/}
	echo "[$scriptName]   version    : $version (latest)"
else
	echo "[$scriptName]   version    : $version"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

if [ ! -z "$http_proxy" ]; then
	echo "[$scriptName]   http_proxy : $http_proxy"
	optArg="--proxy $http_proxy"
else
	echo "[$scriptName]   http_proxy : (not set)"
fi

executeExpression "curl -sL $optArg https://archive.apache.org/dist/maven/maven-3/${version}/binaries/apache-maven-${version}-bin.tar.gz | tar zx"
executeExpression "runTime=\"apache-maven-${version}\""
if [ -d "/opt/$runTime" ]; then
	executeExpression "$elevate rm -rf '/opt/$runTime'"
fi
executeExpression "$elevate mv $runTime /opt/"

# Configure to directory on the default PATH
if [ -L "/usr/bin/mvn" ]; then
	executeExpression "$elevate unlink /usr/bin/mvn"
fi
if [ -f "/usr/bin/mvn" ]; then
	executeExpression "$elevate rm -f /usr/bin/mvn"
fi
executeExpression "$elevate ln -s /opt/$runTime/bin/mvn /usr/bin/mvn"

echo "[$scriptName] Verify install (reload environment variables first)..."
for script in $(find /etc/profile.d/ -mindepth 1 -maxdepth 1 -type f -name '*.sh'); do
	executeExpression "source $script"
done

# Maven version lists to standard error
test=$(mvn -version 2>&1)
exit_code=$?
if [ $exit_code -eq 0 ]; then
	IFS=' ' read -ra ADDR <<< $test
	echo "Maven version ${ADDR[2]} installed."
else
	echo "    Maven instasll failed!"
	exit $exit_code
fi

echo "[$scriptName] --- end ---"
