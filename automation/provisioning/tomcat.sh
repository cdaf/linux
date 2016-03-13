#!/usr/bin/env bash

echo "tomcat.sh : --- start ---"
if [ -z "$1" ]; then
	echo "version not passed, HALT!"
	exit 1
else
	version="$1"
	echo "tomcat.sh : version     : $version"
fi

# Set parameters
tomcat="apache-tomcat-${version}"
echo "tomcat.sh : tomcat      : $tomcat"
appRoot='/opt/apache'
echo "tomcat.sh : appRoot     : $appRoot"

# Create and Configure Deployment user
echo 'Create the runtime user (tomcat)'
centos=$(uname -a | grep el)
if [ -z "$centos" ]; then
	echo "Ubuntu/Debian : sudo adduser --disabled-password --gecos \"\" tomcat"
	sudo adduser --disabled-password --gecos "" tomcat
else
	echo "CentOS/RHEL : sudo adduser tomcat"
	sudo adduser tomcat
fi

echo
echo 'Create application root directory and change to runtime directory'
sudo mkdir -p $appRoot
cd $appRoot

echo 'Copy media and extract'
cp -v "/vagrant/.provisioning/${tomcat}.tar.gz" .
tar -zxf ${tomcat}.tar.gz

echo 'Make all objects executable and owned by tomcat service account'
sudo chown -R tomcat:tomcat $tomcat
sudo chmod 755 -R $tomcat

echo 'Retain the default tomcat console'
cd $tomcat
mv -v webapps/ROOT/ webapps/console

echo 'Start the server, as tomcat user'
sudo ln -sv $appRoot/$tomcat /opt/tomcat
sudo -H -u tomcat bash -c '/opt/tomcat/bin/startup.sh'

echo "tomcat.sh : --- end ---"
