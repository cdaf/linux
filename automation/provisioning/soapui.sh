#!/usr/bin/env bash
set -e
set -x #echo on

echo "soupui.sh : --- start ---"

# Version is set by the build process and is static for any given copy of this script
version="@buildNumber@"
echo "soupui.sh : buildNumber : $buildNumber"

if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
fi

# Set parameters
soapuiVersion="SoapUI-${version}"
soapuiSource="${soapuiVersion}-linux-bin.tar.gz"

cp "/vagrant/.provisioning/${soapuiSource}" .
tar -xf $soapuiSource
sudo mv $soapuiVersion /opt/

# Configure to directory on the default PATH
sudo ln -s /opt/$soapuiVersion/ /opt/soapui

echo "soupui.sh : --- end ---"
