#!/usr/bin/env bash
set -e
set -x #echo on

echo "ant.sh : --- start ---"

# Version is set by the build process and is static for any given copy of this script
buildNumber="@buildNumber@"
echo "ant.sh : buildNumber : $buildNumber"

if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
fi

# Set parameters
antVersion="apache-ant-${version}"
antSource="$antVersion-bin.tar.gz"

cp "/vagrant/.provisioning/${antSource}" .
tar -xf $antSource
sudo mv $antVersion /opt/

# Configure to directory on the default PATH
sudo ln -s /opt/$antVersion/bin/ant /usr/bin/ant

# Set environment (user default) variable
echo ANT_HOME=\"/opt/$antVersion\" > ant.sh
chmod +x ant.sh
sudo mv -v ant.sh /etc/profile.d/

echo "ant.sh : --- end ---"
