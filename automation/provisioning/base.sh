#!/usr/bin/env bash
# set -e, do not set this, grep exit is 1 when string not found, this will cause the process to halt
# set -x

echo "base.sh : --- start ---"

# Version is set by the build process and is static for any given copy of this script
buildnumber="@buildnumber@"
echo "base.sh : buildnumber : $buildnumber"

install=$1

echo "base.sh : install     : $install"

# Base requirements for CDAF, only supporting CentOS and Ubuntu
echo "Determine distribution, only Ubuntu/Debian and CentOS/RHEL supported"
uname -a
centos=$(uname -a | grep el)

echo "Install base software ($install)"
if [ -z "$centos" ]; then
	echo "Ubuntu/Debian, update repositories using apt-get"
	sudo apt-get update
	sudo apt-get install -y $install
else
	echo "CentOS/RHEL, update repositories using yum"
	sudo yum check-update
	sudo yum install -y $install
fi
 
echo "base.sh : --- end ---"
