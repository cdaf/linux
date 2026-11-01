#!/usr/bin/env bash

# Install latest version
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/installApacheAnt.sh | bash -

# Install specific version (positional or named)
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/installApacheAnt.sh | bash -s -- '1.10.16'
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/installApacheAnt.sh | bash -s -- -version '1.10.16'

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

function usage {
	echo "Usage: $scriptName [-version <version>] [-help]"
	echo "       $scriptName [<version>]"
	echo ""
	echo "  -version  Apache Ant version to install, default is latest"
	echo "  -help     Display this message"
	echo ""
	echo "Requires JAVA_HOME to be set."
}

# Support named parameters, with the first non-option argument treated as version (positional)
while [ $# -gt 0 ]; do
	case "$1" in
		-help|--help|-h|-\?)
			usage
			exit 0
			;;
		-version)
			if [ -z "$2" ]; then
				echo "[$scriptName] -version requires a value!"
				usage
				exit 1
			fi
			version="$2"
			shift 2
			;;
		-*)
			echo "[$scriptName] Unknown option $1"
			usage
			exit 1
			;;
		*)
			version="$1"
			shift
			;;
	esac
done

echo "[$scriptName] --- start ---"
if [ -z "$JAVA_HOME" ]; then
	echo "[$scriptName] JAVA_HOME is not set, Apache Ant requires Java, install Java and set JAVA_HOME before proceeding!"
	exit 1
fi
echo "[$scriptName]   JAVA_HOME  : $JAVA_HOME"

if [ -z "$version" ]; then
    URL="https://ant.apache.org/bindownload.cgi"
	version=$(curl -sL "$URL" | grep -oP 'Apache Ant \K[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
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
test=$(ant -version 2>&1)
exit_code=$?
if [ $exit_code -eq 0 ]; then
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[3]}
	echo "[$scriptName] Apache Ant version $test"
else
	echo "[$scriptName] Apache Ant install failed!"
	ant -version
	exit $exit_code
fi

echo "[$scriptName] --- end ---"
