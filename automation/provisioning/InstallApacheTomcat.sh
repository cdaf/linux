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

scriptName='InstallApacheTomcat.sh'

echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version='8.5.20'
	echo "[$scriptName]   version        : $version (default)"
else
	echo "[$scriptName]   version        : $version"
fi

appRoot="$2"
if [ -z "$appRoot" ]; then
	appRoot='/opt/tomcat'
	echo "[$scriptName]   appRoot        : $appRoot (default)"
else
	echo "[$scriptName]   appRoot        : $appRoot"
fi

serviceAccount="$3"
if [ -z "$serviceAccount" ]; then
	serviceAccount='tomcat'
	echo "[$scriptName]   serviceAccount : $serviceAccount (default)"
else
	echo "[$scriptName]   serviceAccount : $serviceAccount"
fi

mediaCache="$4"
if [ -z "$mediaCache" ]; then
	mediaCache='/.provision'
	echo "[$scriptName]   mediaCache     : $mediaCache (default)"
else
	echo "[$scriptName]   mediaCache     : $mediaCache"
fi

echo
# Set parameters
tomcat="apache-tomcat-${version}"
echo "[$scriptName]   \$tomcat        = $tomcat"
mediaFullPath="$mediaCache/${tomcat}.tar.gz"
echo "[$scriptName]   \$mediaFullPath = $mediaFullPath"

# Check for media
if [ -f $mediaCache/${tomcat}.tar.gz ]; then
	echo "[$scriptName] Media found $mediaFullPath"
else
	echo "[$scriptName] Media not found, attempting download"
	if [ ! -d "$mediaCache" ]; then
		executeExpression "sudo mkdir -p $mediaCache"
	fi
	executeExpression "sudo curl -s --output $mediaFullPath http://www-us.apache.org/dist/tomcat/tomcat-8/v${version}/bin/${tomcat}.tar.gz"
fi

if [ -n "$(getent passwd $serviceAccount)" ]; then
	echo "[$scriptName] Tomcat user ($serviceAccount) already exists, no action required."
else
	# Create and Configure Deployment user
	centos=$(uname -a | grep el)
	if [ -z "$centos" ]; then
		echo "[$scriptName] Create the runtime user ($serviceAccount) Ubuntu/Debian"
		executeExpression "sudo adduser --disabled-password --gecos \"\" $serviceAccount"
	else
		echo "[$scriptName] Create the runtime user ($serviceAccount) CentOS/RHEL"
		executeExpression "sudo adduser $serviceAccount"
	fi
fi

echo
echo "[$scriptName] Create application root directory and change to runtime directory"
executeExpression "sudo mkdir -p $appRoot"
executeExpression "cd $appRoot"

echo
echo "[$scriptName] Copy media and extract"

executeExpression "sudo cp -v \"$mediaFullPath\" ."
executeExpression "sudo tar -zxf ${tomcat}.tar.gz"

echo
echo "[$scriptName] Retain the default tomcat console"
executeExpression "sudo mv -v $appRoot/$tomcat/webapps/ROOT/ $appRoot/$tomcat/webapps/console"

echo
echo "[$scriptName] Create a link (static for different versions)"
if [ -d "$appRoot/webapps" ]; then
	executeExpression "sudo unlink $appRoot/webapps"
fi
executeExpression "sudo ln -s $appRoot/$tomcat/webapps $appRoot/webapps"

echo
echo "[$scriptName] Make all objects executable and owned by tomcat service account"
executeExpression "sudo chmod 755 -R $tomcat"
executeExpression "sudo chown -R $serviceAccount:$serviceAccount $tomcat"

echo
echo "[$scriptName] Set the application folder to be group writable"
executeExpression "sudo chmod -R g+rwx $appRoot/$tomcat/webapps"

# If a systemd distribution, create service
if [ -d "/etc/systemd/system/" ]; then
	sudo sh -c "echo \"[Unit]\" > /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"Description=Apache Tomcat Web Application Container for ${serviceAccount}\" >> /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"After=syslog.target network.target\" >> /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"[Service]\" >> /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"Type=forking\" >> /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"ExecStart=$appRoot/$tomcat/bin/startup.sh\" >> /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"ExecStop=$appRoot/$tomcat/bin/shutdown.sh\" >> /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"User=${serviceAccount}\" >> /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"Group=${serviceAccount}\" >> /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"[Install]\" >> /etc/systemd/system/${serviceAccount}.service"
	sudo sh -c "echo \"WantedBy=multi-user.target\" >> /etc/systemd/system/${serviceAccount}.service"
fi

executeExpression "sudo systemctl daemon-reload"
executeExpression "sudo systemctl enable ${serviceAccount}"
executeExpression "sudo systemctl start ${serviceAccount}"

echo "[$scriptName] --- end ---"
