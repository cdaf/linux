#!/usr/bin/env bash
scriptName='reverseProxy.sh'

echo "[$scriptName] --- start ---"

# Version is set by the build process and is static for any given copy of this script

if [ -z "$1" ]; then
	echo "URL not passed, HALT!"
	exit 1
else
	url="$1"
	echo "[$scriptName]   url     : $url"
fi

if [ -z "$2" ]; then
	echo "[$scriptName] Context not passed, HALT!"
	exit 2
else
	context="$2"
	echo "[$scriptName]   context : $context"
fi

echo "[$scriptName] Configure the Apache (HTTPD) server"
centos=$(uname -a | grep el)
if [ -z "$centos" ]; then
	
	echo "[$scriptName] sudo apt-get install -y apache2 libapache2-mod-proxy-html libxml2-dev"
	sudo apt-get update
	sudo apt-get install -y apache2 libapache2-mod-proxy-html libxml2-dev
	
	echo "[$scriptName] cd /etc/apache2/mods-enabled"
	cd /etc/apache2/mods-enabled
	echo "[$scriptName] Create mod links for proxy_http.load, proxy.load, headers.load & proxy_ajp.load"
	sudo ln -s ../mods-available/proxy_http.load .
	sudo ln -s ../mods-available/proxy.load .
	sudo ln -s ../mods-available/headers.load .
	sudo ln -s ../mods-available/proxy_ajp.load .

	echo	
	echo "[$scriptName] Open an elevated shell session for redirection to privilaged files"
	echo "[$scriptName] sudo sh -c \'echo \"LoadFile /usr/lib/x86_64-linux-gnu/libxml2.so\" >> /etc/apache2/mods-enabled/proxy_html.conf\'"
	sudo sh -c 'echo "LoadFile /usr/lib/x86_64-linux-gnu/libxml2.so" >> /etc/apache2/mods-enabled/proxy_html.conf'
	
	echo	
	echo "[$scriptName] Add the supplied URL to the reverse proxy rule"
	# Remove the closing tag from the default and append mapping
	sudo sed -i '/<\/VirtualHost>/d' /etc/apache2/sites-enabled/000-default.conf
	sudo sh -c 'echo "    <IfModule mod_proxy.c>" >> /etc/apache2/sites-enabled/000-default.conf'
	sudo sh -c 'echo "        # Applied by CDAF provisioning" >> /etc/apache2/sites-enabled/000-default.conf'
	sudo sh -c "echo \"        ProxyPass /$context $url/$context\" >> /etc/apache2/sites-enabled/000-default.conf"
	sudo sh -c "echo \"        ProxyPassReverse /$context $url/$context\" >> /etc/apache2/sites-enabled/000-default.conf"
	sudo sh -c 'echo "    </IfModule>" >> /etc/apache2/sites-enabled/000-default.conf'
	sudo sh -c 'echo "</VirtualHost>" >> /etc/apache2/sites-enabled/000-default.conf'

	echo	
	echo "[$scriptName] Start the server"
	echo "[$scriptName] sudo service apache2 restart"
	sudo service apache2 restart

else

	echo	
	echo "[$scriptName] sudo yum install -y httpd"
	sudo yum install -y httpd

	echo	
	echo "[$scriptName] Add the supplied URL to the reverse proxy rule"
	sudo sh -c 'echo "<VirtualHost *:80>" > /etc/httpd/conf.d/httpproxy.conf'
	sudo sh -c 'echo "    <IfModule mod_proxy.c>" >> /etc/httpd/conf.d/httpproxy.conf'
	sudo sh -c 'echo "        # Applied by CDAF provisioning" >> /etc/httpd/conf.d/httpproxy.conf'
	sudo sh -c "echo \"        ProxyPass /$context $url/$context\" >> /etc/httpd/conf.d/httpproxy.conf"
	sudo sh -c "echo \"        ProxyPassReverse /$context $url/$context\" >> /etc/httpd/conf.d/httpproxy.conf"
	sudo sh -c 'echo "    </IfModule>" >> /etc/httpd/conf.d/httpproxy.conf'
	sudo sh -c 'echo "</VirtualHost>" >> /etc/httpd/conf.d/httpproxy.conf'
	
	echo	
	echo "[$scriptName] Start the server"
	echo "[$scriptName] sudo apachectl configtest"
	sudo apachectl configtest
	echo "[$scriptName] sudo systemctl enable httpd.service"
	sudo systemctl enable httpd.service
	echo "[$scriptName] sudo systemctl start httpd.service"
	sudo systemctl start httpd.service
	echo "[$scriptName] systemctl is-active httpd.service"
	systemctl is-active httpd.service

	echo	
	echo "[$scriptName] Open Firewall"
	echo "[$scriptName] sudo firewall-cmd --zone=public --add-port=80/tcp --permanent"
	sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
	echo "[$scriptName] sudo firewall-cmd --reload"
	sudo firewall-cmd --reload
fi

echo "[$scriptName] --- end ---"
