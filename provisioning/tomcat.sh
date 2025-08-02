#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

scriptName='tomcat.sh'

echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version='8.5.4'
	echo "[$scriptName]   version : $version (default)"
else
	echo "[$scriptName]   version : $version"
fi

appRoot="$2"
if [ -z "$appRoot" ]; then
	appRoot='/opt/apache'
	echo "[$scriptName]   appRoot : $appRoot (default)"
else
	echo "[$scriptName]   appRoot : $appRoot"
fi

# Set parameters
tomcat="apache-tomcat-${version}"
echo "[$scriptName]   tomcat  : $tomcat"

if [ -z "$(getent passwd tomcat)" ]; then
	# Create and Configure Deployment user
	# Create and Configure Deployment user
	echo "[$scriptName] Create the runtime user ($serviceAccount)"
	executeExpression "$elevate useradd -m -k /dev/null -u $userID -s /usr/sbin/nologin -c '' tomcat"
else
	echo "[$scriptName] Tomcat user (tomcat) alrady exists, no action required."
fi

echo
echo "[$scriptName] Create application root directory and change to runtime directory"
executeExpression "sudo mkdir -p $appRoot"
executeExpression "cd $appRoot"

echo
echo "[$scriptName] Copy media and extract"
executeExpression "cp -v \"/vagrant/.provision/${tomcat}.tar.gz\" ."
executeExpression "tar -zxf ${tomcat}.tar.gz"

echo
echo "[$scriptName] Make all objects executable and owned by tomcat service account"
executeExpression "sudo chown -R tomcat:tomcat $tomcat"
executeExpression "sudo chmod 755 -R $tomcat"

cd $tomcat
echo
echo "[$scriptName] Set the application folder to be group writable"
executeExpression "sudo chmod -R g+rwx webapps"

echo
echo "[$scriptName] Retain the default tomcat console"
executeExpression "mv -v webapps/ROOT/ webapps/console"

echo
echo "[$scriptName] Create symlink and start the server, as tomcat user"
executeExpression "sudo ln -sv $appRoot/$tomcat /opt/tomcat"
executeExpression "sudo -H -u tomcat bash -c \'/opt/tomcat/bin/startup.sh\'"

echo "[$scriptName] --- end ---"
