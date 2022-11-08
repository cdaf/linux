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
	version='1.10.12'
	echo "[$scriptName]   version    : $version (default)"
else
	version="$1"
	echo "[$scriptName]   version    : $version"
fi

mediaCache="$2"
if [ -z "$mediaCache" ]; then
	mediaCache='/.provision'
	echo "[$scriptName]   mediaCache : $mediaCache (default)"
else
	echo "[$scriptName]   mediaCache : $mediaCache"
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

if [ ! -f ${mediaCache}/${antSource} ]; then
	echo "[$scriptName] Media (${mediaCache}/${antSource}) not found, attempting download ..."
	executeExpression "curl -s -o ${mediaCache}/${antSource} \"http://archive.apache.org/dist/ant/binaries/${antSource}\""
fi

executeExpression "cp \"${mediaCache}/${antSource}\" ."
executeExpression "tar -xf $antSource"
executeExpression "$elevate mv $antVersion /opt/"

# Configure to directory on the default PATH
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
