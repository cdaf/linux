#!/usr/bin/env bash
scriptName='node.sh'
versionChoices='4 or 6'
echo
echo "[$scriptName] --- start ---"
centos=$(uname -mrs | grep .el)
if [ "$centos" ]; then
	echo "[$scriptName]   Fedora based : $(uname -mrs)"
else
	ubuntu=$(uname -a | grep ubuntu)
	if [ "$ubuntu" ]; then
		echo "[$scriptName]   Debian based : $(uname -mrs)"
	else
		echo "[$scriptName]   $(uname -a), proceeding assuming Debian based..."; echo
	fi
fi

version=$1
if [ "${version}" ]; then
	echo "[$scriptName]   version      : $version (choices ${versionChoices})"
else
	version=6
	echo "[$scriptName]   version      : $version (default, choices ${versionChoices})"
fi

case ${version} in
4)
	;;
6)
	;;
*)
	echo "[$scriptName] Unsupported version! Supported versions are ${versionChoices}."
	exit 1
esac

if [ "$centos" ]; then

	echo "[$scriptName] CentOS/RHEL, using https://rpm.nodesource.com/setup_${version}.x"
	curl --silent --location https://rpm.nodesource.com/setup_${version}.x | bash -
	sudo yum -d1 install -y nodejs npm

else

	echo "[$scriptName] Ubuntu/Debian, using https://deb.nodesource.com/setup_${version}.x"
	curl -sL https://deb.nodesource.com/setup_${version}.x | sudo -E bash -
	sudo apt-get install -y nodejs

fi

echo "[$scriptName] Verify version"
node -v

echo "[$scriptName] --- end ---"
