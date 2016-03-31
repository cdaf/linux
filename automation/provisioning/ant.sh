#!/usr/bin/env bash
scriptName='ant.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
	echo "[$scriptName]   version    : $version"
fi

# Set parameters
antVersion="apache-ant-${version}"
echo "[$scriptName]   antVersion : $antVersion"
antSource="$antVersion-bin.tar.gz"
echo "[$scriptName]   antSource  : $antSource"

echo "[$scriptName] cp /vagrant/.provision/${antSource} ."
cp "/vagrant/.provision/${antSource}" .
echo "[$scriptName] tar -xf $antSource"
tar -xf $antSource
echo "[$scriptName] sudo mv $antVersion /opt/"
sudo mv $antVersion /opt/

# Configure to directory on the default PATH
echo "[$scriptName] sudo ln -s /opt/$antVersion/bin/ant /usr/bin/ant"
sudo ln -s /opt/$antVersion/bin/ant /usr/bin/ant

# Set environment (user default) variable
echo "[$scriptName] ANT_HOME=\"/opt/$antVersion\" > $scriptName"
echo ANT_HOME=\"/opt/$antVersion\" > $scriptName
echo "[$scriptName] chmod +x $scriptName"
chmod +x $scriptName
echo "[$scriptName] sudo mv -v $scriptName /etc/profile.d/"
sudo mv -v $scriptName /etc/profile.d/

echo "[$scriptName] --- end ---"
