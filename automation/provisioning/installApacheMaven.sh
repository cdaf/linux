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
scriptName='installApacheMaven.sh'

echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version=$(curl -s https://maven.apache.org/download.cgi | grep 'Downloading Apache Maven')
	version=${version//'<h1>Downloading Apache Maven '/}
	version=${version//'</h1>'/}
	echo "[$scriptName]   version    : $version (latest)"
else
	echo "[$scriptName]   version    : $version"
fi

mediaPath="$2"
if [ -z "$mediaPath" ]; then
	mediaPath='/.provision'
	echo "[$scriptName]   mediaPath  : $mediaPath (default)"
else
	echo "[$scriptName]   mediaPath  : $mediaPath"
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

# Check for media
echo
mediaFullPath="$mediaPath/apache-maven-${version}-bin.tar.gz"
echo "[$scriptName] \$mediaFullPath = $mediaFullPath"
if [ -f "$mediaFullPath" ]; then
	echo "[$scriptName] Media found $mediaFullPath"
else
	echo "[$scriptName] Media not found, attempting download"
	if [ ! -d "$mediaPath" ]; then
		executeExpression "$elevate mkdir -p $mediaPath"
	fi
	executeExpression "$elevate curl -s -o $mediaFullPath $optArg https://archive.apache.org/dist/maven/maven-3/${version}/binaries/apache-maven-${version}-bin.tar.gz"
fi

# Set parameters
executeExpression "runTime=\"apache-maven-${version}\""
executeExpression "sourceFile=\"$runTime-bin.tar.gz\""

executeExpression "cp \"$mediaPath/${sourceFile}\" ."
executeExpression "tar -xf $sourceFile"
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
executeExpression "mvn --version"

echo "[$scriptName] --- end ---"
