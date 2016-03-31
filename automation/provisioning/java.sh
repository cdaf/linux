#!/usr/bin/env bash
scriptName='java.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "[$scriptName]   version not passed, HALT!"
	exit 1
else
	version="$1"
	echo "[$scriptName]   version    : $version"
fi

if [ -z "$2" ]; then
	echo "[$scriptName]   prefix not passed, defaulting to jre"
	prefix='jre'
	echo "[$scriptName]   prefix     : $prefix (default)"
else
	prefix="$2"
	echo "[$scriptName]   prefix     : $prefix"
fi

if [ -z "$3" ]; then
	mediaCache='/vagrant/.provision/'
	echo "[$scriptName]   mediaCache : $mediaCache (default)"
else
	mediaCache="$3"
	echo "[$scriptName]   mediaCache : $mediaCache"
fi

jdkSource="${prefix}-${version}-linux-x64.tar.gz"
echo "[$scriptName] jdkSource  : $jdkSource"
jdkExtract="${prefix}${version}"
echo "[$scriptName] jdkExtract : $jdkExtract"

# Extract the Java binaries
echo "[$scriptName] cp \"$mediaCache/${jdkSource}\" ."
cp "$mediaCache/${jdkSource}" .
echo "[$scriptName] tar -zxf $jdkSource"
tar -zxf $jdkSource
echo "[$scriptName] sudo mv $jdkExtract/ /opt/"
sudo mv $jdkExtract/ /opt/

# Configure to directory on the default PATH, always set the JRE, only set JDK if requested
if [ "$prefix" == "jdk" ]; then
	echo "[$scriptName] sudo ln -s /opt/$jdkExtract/bin/javac /usr/bin/javac"
	sudo ln -s /opt/$jdkExtract/bin/javac /usr/bin/javac
fi
echo "[$scriptName] sudo ln -s /opt/$jdkExtract/bin/javac /usr/bin/javac"
sudo ln -s /opt/$jdkExtract/bin/java /usr/bin/java

# Set the environment settings (requires elevation)
echo "[$scriptName] echo JAVA_HOME=\"/opt/$jdkExtract/bin\" > oracle-jdk.sh"
echo JAVA_HOME=\"/opt/$jdkExtract/bin\" > oracle-jdk.sh
echo "[$scriptName] chmod +x oracle-jdk.sh"
chmod +x oracle-jdk.sh
echo "[$scriptName] sudo mv -v oracle-jdk.sh /etc/profile.d/"
sudo mv -v oracle-jdk.sh /etc/profile.d/

echo "[$scriptName] --- end ---"
