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
scriptName='soapui.sh'

echo "[scriptName] : --- start ---"
version="$1"
if [ -z "$version" ]; then
	echo "version not passed, HALT! Exit with code 1"; exit 1
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

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

if [ ! -d "$mediaCache" ]; then
	executeExpression "mkdir $mediaCache"
fi

# Set parameters
executeExpression "soapuiVersion=\"SoapUI-${version}\""
executeExpression "soapuiSource=\"${soapuiVersion}-linux-bin.tar.gz\""

if [ ! -f ${mediaCache}/${soapuiSource} ]; then
	echo "[$scriptName] Media (${mediaCache}/${soapuiSource}) not found, attempting download ..."
	executeExpression "curl -s -o ${mediaCache}/${soapuiSource} \"http://smartbearsoftware.com/distrib/soapui/${version}/${soapuiSource}\""
fi

executeExpression "cp \"${mediaCache}/${soapuiSource}\" ."
executeExpression "tar -xf $soapuiSource"
executeExpression "$elevate mv $soapuiVersion /opt/"

# Configure to directory on the default PATH
executeExpression "$elevate ln -s /opt/$soapuiVersion/ /opt/soapui"

echo "[scriptName] : --- end ---"
