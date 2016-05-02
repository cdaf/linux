#!/usr/bin/env bash
scriptName='tomcat.sh'

echo "[$scriptName] --- start ---"
if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
	echo "[$scriptName]   version     : $version"
fi

# Set parameters
tomcat="apache-tomcat-${version}"
echo "[$scriptName]   tomcat      : $tomcat"
appRoot='/opt/apache'
echo "[$scriptName]   appRoot     : $appRoot"

# Create and Configure Deployment user
echo "[$scriptName] Create the runtime user (tomcat)"
centos=$(uname -a | grep el)
if [ -z "$centos" ]; then
	echo "[$scriptName] Ubuntu/Debian : sudo adduser --disabled-password --gecos \"\" tomcat"
	sudo adduser --disabled-password --gecos "" tomcat
else
	echo "[$scriptName] CentOS/RHEL : sudo adduser tomcat"
	sudo adduser tomcat
fi

echo
echo "[$scriptName] Create application root directory and change to runtime directory"
sudo mkdir -p $appRoot
cd $appRoot

echo
echo "[$scriptName] Copy media and extract"
cp -v "/vagrant/.provision/${tomcat}.tar.gz" .
tar -zxf ${tomcat}.tar.gz

echo
echo "[$scriptName] Make all objects executable and owned by tomcat service account"
sudo chown -R tomcat:tomcat $tomcat
sudo chmod 755 -R $tomcat

echo
echo "[$scriptName] Retain the default tomcat console"
cd $tomcat
mv -v webapps/ROOT/ webapps/console

echo
echo "[$scriptName] Start the server, as tomcat user"
sudo ln -sv $appRoot/$tomcat /opt/tomcat
sudo -H -u tomcat bash -c '/opt/tomcat/bin/startup.sh'

echo "[$scriptName] --- end ---"
