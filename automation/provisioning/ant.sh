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
scriptName='ant.sh'

echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	echo "[$scriptName]   version    : $version"
fi

mediaCache="$2"
if [ -z "$mediaCache" ]; then
	mediaCache='/.provision'
	echo "[$scriptName]   mediaCache : $mediaCache (default)"
else
	echo "[$scriptName]   mediaCache : $mediaCache"
fi

echo
# Set parameters
executeExpression "antVersion=\"apache-ant-${version}\""
executeExpression "antSource=\"$antVersion-bin.tar.gz\""

executeExpression "cp \"${mediaCache}/${antSource}\" ."
executeExpression "tar -xf $antSource"
executeExpression "sudo mv $antVersion /opt/"

# Configure to directory on the default PATH
executeExpression "sudo ln -s /opt/$antVersion/bin/ant /usr/bin/ant"

# Set environment (user default) variable
echo ANT_HOME=\"/opt/$antVersion\" > $scriptName
chmod +x $scriptName
sudo mv -v $scriptName /etc/profile.d/

echo "[$scriptName] List start script contents ..."
executeExpression "cat /etc/profile.d/$scriptName"

echo "[$scriptName] --- end ---"
