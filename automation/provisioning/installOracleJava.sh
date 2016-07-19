#!/usr/bin/env bash
scriptName='installOracleJava.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	prefix='jdk'
	echo "[$scriptName]   prefix     : $prefix (default)"
else
	prefix="$1"
	echo "[$scriptName]   prefix     : $prefix"
fi

if [ -z "$2" ]; then
	version='8u91'
	echo "[$scriptName]   version    : $version (default)"
else
	version="$2"
	echo "[$scriptName]   version    : $version"
fi

if [ -z "$3" ]; then
	mediaCache='/vagrant/.provision/'
	echo "[$scriptName]   mediaCache : $mediaCache (default)"
else
	mediaCache="$3"
	echo "[$scriptName]   mediaCache : $mediaCache"
fi
echo
initialDir=$(pwd)
javaSource="${prefix}-${version}-linux-x64.tar.gz"
echo "[$scriptName] \$javaSource = $javaSource"
javaExtract="${prefix}-${version}"
echo "[$scriptName] \$javaExtract = $javaExtract"

cd ~
echo "[$scriptName] Extract the Java binaries in users home ($(pwd))"
echo "[$scriptName] cp \"$mediaCache/${javaSource}\" ."
cp "$mediaCache/${javaSource}" .
echo "[$scriptName] mkdir $javaExtract"
mkdir $javaExtract
echo "[$scriptName] tar -zxf $javaSource -C $javaExtract --strip-components=1"
tar -zxf $javaSource -C $javaExtract --strip-components=1
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : tar -zxf $javaSource failed! Returned $exitCode"
	exit $exitCode
fi
echo "[$scriptName] sudo mv $javaExtract/ /opt/"
sudo mv $javaExtract/ /opt/

# Configure to directory on the default PATH, always set the JRE, only set JDK if requested
if [ "$prefix" == "jdk" ]; then
	if [ -L "/usr/bin/javac" ]; then
		echo "[$scriptName] Delete existing symlink"
		echo "[$scriptName] sudo unlink /usr/bin/javac"
		sudo unlink /usr/bin/javac
	fi
	echo "[$scriptName] sudo ln -s /opt/$javaExtract/bin/javac /usr/bin/javac"
	sudo ln -s /opt/$javaExtract/bin/javac /usr/bin/javac
fi
if [ -L "/usr/bin/java" ]; then
	echo "[$scriptName] Delete existing symlink"
	echo "[$scriptName] sudo unlink /usr/bin/java"
	sudo unlink /usr/bin/java
fi
echo "[$scriptName] sudo ln -s /opt/$javaExtract/bin/java /usr/bin/java"
sudo ln -s /opt/$javaExtract/bin/java /usr/bin/java

# Set the environment settings (requires elevation), replace if existing
echo "[$scriptName] echo export JAVA_HOME=\"/opt/$javaExtract/bin\" > oracle-java.sh"
echo export JAVA_HOME=\"/opt/$javaExtract/bin\" > oracle-java.sh
echo "[$scriptName] chmod +x oracle-java.sh"
chmod +x oracle-java.sh
echo "[$scriptName] sudo mv -v oracle-java.sh /etc/profile.d/"
sudo mv -v oracle-java.sh /etc/profile.d/

# Execute the script to set the variable 
source /etc/profile.d/oracle-java.sh

echo "[$scriptName] Return to initial directory ($initialDir)"
cd $initialDir
echo "[$scriptName] --- end ---"
