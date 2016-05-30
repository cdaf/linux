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
scriptName='addUser.sh'

echo "[scriptName] : --- start ---"
if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
fi

# Set parameters
executeExpression "soapuiVersion=\"SoapUI-${version}\""
executeExpression "soapuiSource=\"${soapuiVersion}-linux-bin.tar.gz\""

executeExpression "cp \"/vagrant/.provision/${soapuiSource}\" ."
executeExpression "tar -xf $soapuiSource"
executeExpression "sudo mv $soapuiVersion /opt/"

# Configure to directory on the default PATH
executeExpression "sudo ln -s /opt/$soapuiVersion/ /opt/soapui"

echo "[scriptName] : --- end ---"
