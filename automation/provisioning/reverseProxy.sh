#!/usr/bin/env bash
set -x #echo on

echo "reverseProxy.sh : --- start ---"

# Version is set by the build process and is static for any given copy of this script

if [ -z "$1" ]; then
	echo "URL not passed, HALT!"
	exit 1
else
	url="$1"
	echo "reverseProxy.sh : url     : $url"
fi

if [ -z "$2" ]; then
	echo "Context not passed, HALT!"
	exit 2
else
	context="$2"
	echo "reverseProxy.sh : context : $context"
fi

echo 'Configure the Apache (HTTPD) server'
centos=$(uname -a | grep el)
if [ -z "$centos" ]; then
	
	sudo apt-get install -y apache2 libapache2-mod-proxy-html libxml2-dev
	
	cd /etc/apache2/mods-enabled
	sudo ln -s ../mods-available/proxy_http.load .
	sudo ln -s ../mods-available/proxy.load .
	sudo ln -s ../mods-available/headers.load .
	sudo ln -s ../mods-available/proxy_ajp.load .
	# Open an elevated shell for redirection to files
	sudo sh -c 'echo "LoadFile /usr/lib/x86_64-linux-gnu/libxml2.so" >> /etc/apache2/mods-enabled/proxy_html.conf'
	
	# Remove the closing tag from the default and append mapping
	sudo sed -i '/<\/VirtualHost>/d' /etc/apache2/sites-enabled/000-default.conf
	sudo sh -c 'echo "    <IfModule mod_proxy.c>" >> /etc/apache2/sites-enabled/000-default.conf'
	sudo sh -c 'echo "        # Applied by CDAF provisioning" >> /etc/apache2/sites-enabled/000-default.conf'
	sudo sh -c "echo \"        ProxyPass /$context $url/$context\" >> /etc/apache2/sites-enabled/000-default.conf"
	sudo sh -c "echo \"        ProxyPassReverse /$context $url/$context\" >> /etc/apache2/sites-enabled/000-default.conf"
	sudo sh -c 'echo "    </IfModule>" >> /etc/apache2/sites-enabled/000-default.conf'
	sudo sh -c 'echo "</VirtualHost>" >> /etc/apache2/sites-enabled/000-default.conf'
	
	# Start the server
	sudo service apache2 restart
else

	sudo yum install -y httpd

	sudo sh -c 'echo "<VirtualHost *:80>" > /etc/httpd/conf.d/httpproxy.conf'
	sudo sh -c 'echo "    <IfModule mod_proxy.c>" >> /etc/httpd/conf.d/httpproxy.conf'
	sudo sh -c 'echo "        # Applied by CDAF provisioning" >> /etc/httpd/conf.d/httpproxy.conf'
	sudo sh -c "echo \"        ProxyPass /$context $url/$context\" >> /etc/httpd/conf.d/httpproxy.conf"
	sudo sh -c "echo \"        ProxyPassReverse /$context $url/$context\" >> /etc/httpd/conf.d/httpproxy.conf"
	sudo sh -c 'echo "    </IfModule>" >> /etc/httpd/conf.d/httpproxy.conf'
	sudo sh -c 'echo "</VirtualHost>" >> /etc/httpd/conf.d/httpproxy.conf'
	
	sudo apachectl configtest
	sudo systemctl enable httpd.service
	sudo systemctl start httpd.service
	systemctl is-active httpd.service

	sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
	sudo firewall-cmd --reload
fi

echo "reverseProxy.sh : --- end ---"
