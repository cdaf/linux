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

scriptName='installOracleJava.sh'

echo "[$scriptName] --- start ---"
prefix="$1"
if [ -z "$prefix" ]; then
	prefix='jdk'
	echo "[$scriptName]   prefix     : $prefix (default)"
else
	echo "[$scriptName]   prefix     : $prefix"
fi

version="$2"
if [ -z "$version" ]; then
	version='8u151'
	echo "[$scriptName]   version    : $version (default)"
else
	echo "[$scriptName]   version    : $version"
fi

mediaCache="$3"
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

echo
javaSource="${prefix}-${version}-linux-x64.tar.gz"
echo "[$scriptName] \$javaSource = $javaSource"
javaExtract="${prefix}-${version}"
echo "[$scriptName] \$javaExtract = $javaExtract"

# Check for media
mediaFullPath="${mediaCache}/${javaSource}"
if [ -f "$mediaFullPath" ]; then
	echo "[$scriptName] Media found $mediaFullPath"
else
	if [ ! -d "$mediaCache" ]; then
		executeExpression "mkdir $mediaCache"
	fi
	echo "[$scriptName] Media not found, please visit http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html"
	echo "[$scriptName] and download to $mediaCache"
	exit 55
fi

echo "[$scriptName] Extract the Java binaries to current directory $(pwd))"
executeExpression "cp \"$mediaCache/${javaSource}\" ."
executeExpression "mkdir ./$javaExtract"
executeExpression "tar -zxf $javaSource -C $javaExtract --strip-components=1"

echo "[$scriptName] $elevate mv ./$javaExtract/ /opt/ and make public Execute"
executeExpression "$elevate rm -rf /opt/$javaExtract"
executeExpression "$elevate mv $javaExtract/ /opt/"
executeExpression "$elevate chmod -R 755 /opt/$javaExtract"

# Configure to directory on the default PATH, always set the JRE, only set JDK if requested
if [ "$prefix" == "jdk" ]; then
	if [ -L "/usr/bin/javac" ]; then
		echo "[$scriptName] Delete existing symlink"
		executeExpression "$elevate unlink /usr/bin/javac"
	fi
	executeExpression "$elevate ln -s /opt/$javaExtract/bin/javac /usr/bin/javac"
fi
if [ -L "/usr/bin/java" ]; then
	echo "[$scriptName] Delete existing symlink"
	executeExpression "$elevate unlink /usr/bin/java"
fi
executeExpression "$elevate ln -s /opt/$javaExtract/bin/java /usr/bin/java"

# Set the environment settings (requires elevation), replace if existing
echo "[$scriptName] echo export JAVA_HOME=\"/opt/$javaExtract\" > oracle-java.sh"
echo export JAVA_HOME=\"/opt/$javaExtract\" > oracle-java.sh

executeExpression "chmod +x oracle-java.sh"
executeExpression "$elevate mv -v oracle-java.sh /etc/profile.d/"

# Execute the script to set the variable 
executeExpression "source /etc/profile.d/oracle-java.sh"

echo "[$scriptName] --- end ---"
