#!/usr/bin/env bash
set -e
set -x #echo on

echo "app.sh : --- start ---"

# Version is set by the build process and is static for any given copy of this script
buildnumber="@buildnumber@"
echo "app.sh : buildnumber : $buildnumber"

if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
fi

# Set parameters
tomcat="/opt/apache/apache-tomcat-${version}"

# Update the deployer account to have access
sudo usermod -G tomcat deployer
sudo chmod -R g+rwx $tomcat/webapps/
sudo mkdir -p /opt/packages/
sudo chown deployer:tomcat /opt/packages/

echo "app.sh : --- end ---"
