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
scriptName='installApacheAnt.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	version=$(curl -s https://downloads.apache.org/ant/ | grep 'Release Notes of Apache Ant')
	version=${version//'<head>Release Notes of Apache Ant '/}
	version=${version//'</head>'/}
	echo "[$scriptName]   version    : $version (latest)"
else
	version="$1"
	echo "[$scriptName]   version    : $version"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

if [ ! -d "$mediaCache" ]; then
	executeExpression "$elevate mkdir -p $mediaCache"
fi

# Set parameters
executeExpression "antVersion=\"apache-ant-${version}\""
executeExpression "antSource=\"$antVersion-bin.tar.gz\""

executeExpression "curl -sL $optArg https://archive.apache.org/dist/ant/binaries/${antSource} | tar zx"

if [ -d "/opt/$antVersion" ]; then
	executeExpression "$elevate rm -rf '/opt/$antVersion'"
fi
executeExpression "$elevate mv $antVersion /opt/"

# Configure to directory on the default PATH
if [ -L "/usr/bin/ant" ]; then
	executeExpression "$elevate unlink /usr/bin/ant"
fi
if [ -f "/usr/bin/ant" ]; then
	executeExpression "$elevate rm -f /usr/bin/ant"
fi
executeExpression "$elevate ln -s /opt/$antVersion/bin/ant /usr/bin/ant"

# Set environment (user default) variable
echo ANT_HOME=\"/opt/$antVersion\" > $scriptName
chmod +x $scriptName
executeExpression "$elevate mv -v $scriptName /etc/profile.d/"

echo "[$scriptName] List start script contents ..."
executeExpression "cat /etc/profile.d/$scriptName"

echo "[$scriptName] Reload environment variables and verify version ..."
for script in $(find /etc/profile.d/ -mindepth 1 -maxdepth 1 -type f -name '*.sh'); do
	executeExpression "source $script"
done

# Ant version lists to standard error
test="`ant -version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Apache Ant install failed!"
	exit 23700
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[3]}
	echo "[$scriptName] Apache Ant version $test"
fi	

echo "[$scriptName] --- end ---"
