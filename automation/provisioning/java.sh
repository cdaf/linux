#!/usr/bin/env bash
set -e
set -x #echo on

echo "java.sh : --- start ---"

# Version is set by the build process and is static for any given copy of this script
version="@buildnumber@"
echo "java.sh : buildnumber : $buildnumber"

if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
fi

if [ -z "$2" ]; then
	echo "prefix not passed, defaulting to jre"
	prefix='jre'
else
	prefix="$2"
fi

cd ~

jdkSource="${prefix}-${version}-linux-x64.tar.gz"
jdkExtract="${prefix}${version}"

# Extract the Java binaries
cp "/vagrant/.provisioning/${jdkSource}" .
tar -zxf $jdkSource
sudo mv $jdkExtract/ /opt/

# Configure to directory on the default PATH
if [ "$prefix" == "jdk" ]; then
	sudo ln -s /opt/$jdkExtract/bin/javac /usr/bin/javac
fi
sudo ln -s /opt/$jdkExtract/bin/java /usr/bin/java

# Set the environment settings
echo JAVA_HOME=\"/opt/$jdkExtract/bin\" > oracle-jdk.sh
chmod +x oracle-jdk.sh
sudo mv -v oracle-jdk.sh /etc/profile.d/

echo "java.sh : --- end ---"
