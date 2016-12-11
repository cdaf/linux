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
	mediaCache='/provision'
	echo "[$scriptName]   mediaCache : $mediaCache (default)"
else
	echo "[$scriptName]   mediaCache : $mediaCache"
fi

# Set parameters
executeExpression "soapuiVersion=\"SoapUI-${version}\""
executeExpression "soapuiSource=\"${soapuiVersion}-linux-bin.tar.gz\""

executeExpression "cp \"${mediaCache}/${soapuiSource}\" ."
executeExpression "tar -xf $soapuiSource"
executeExpression "sudo mv $soapuiVersion /opt/"

# Configure to directory on the default PATH
executeExpression "sudo ln -s /opt/$soapuiVersion/ /opt/soapui"

echo "[scriptName] : --- end ---"
