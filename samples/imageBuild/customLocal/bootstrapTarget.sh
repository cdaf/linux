#!/usr/bin/env bash
function executeExpression {
	counter=1
	max=2
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval $1
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		else
			success='yes'
		fi
	done
}  

scriptName='bootstrapTarget.sh'

# Based on https://gorails.com/deploy/ubuntu/20.04

echo "[$scriptName] --- start ---"
echo "[$scriptName] Working directory is $(pwd)"
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami  : $(whoami)"
else
	echo "[$scriptName]   whoami  : $(whoami) (elevation not required)"
fi

if [ ! -z "$http_proxy" ]; then
	echo "[$scriptName]   http_proxy : $http_proxy"
	optArg="--proxy $http_proxy"
else
	echo "[$scriptName]   http_proxy : (not set)"
fi

atomicPath='./automation'
if [ ! -d "$atomicPath" ]; then
	echo "[$scriptName] Provisioning directory ($atomicPath) not found in workspace, looking for alternative ..."
	atomicPath='/vagrant/automation'
	if [ -d "$atomicPath" ]; then
		echo "[$scriptName] $atomicPath found, will use for script execution"
	else
		echo "[$scriptName] $atomicPath not found! Exit with error 34"; exit 34
	fi
fi

echo; echo "[$scriptName] Verify curl installed, this will ensure apt-get is available for subsequent steps"
executeExpression "$atomicPath/provisioning/base.sh curl"
executeExpression "curl --version"

echo
if [ ! -z "$elevate" ]; then
	executeExpression "curl -sL https://deb.nodesource.com/setup_14.x | $elevate -E bash -"
else
	executeExpression 'curl -sL https://deb.nodesource.com/setup_14.x | bash -'
fi

executeExpression "curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | $elevate apt-key add -"
executeExpression "echo 'deb https://dl.yarnpkg.com/debian/ stable main' | $elevate tee /etc/apt/sources.list.d/yarn.list"

echo
systemDependencies='nodejs libsqlite3-dev zlib1g-dev sqlite3 yarn ruby'
systemDependencies="$systemDependencies git-core build-essential libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev"
systemDependencies="$systemDependencies gcc make ruby-all-dev" # Nokogiri native extensions
executeExpression "$elevate $atomicPath/provisioning/base.sh '$systemDependencies'"

executeExpression "$elevate $atomicPath/remote/capabilities.sh"

executeExpression 'ruby -v'

executeExpression "$elevate gem install bundler"

executeExpression 'bundle -v'

### Old provisioning for running in server
# executeExpression "$elevate apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7"

# executeExpression "$elevate sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger focal main > /etc/apt/sources.list.d/passenger.list'"
# executeExpression "$elevate apt-get update"
# executeExpression "$elevate apt-get install -y nginx-extras libnginx-mod-http-passenger"

# if [ ! -f "/etc/nginx/modules-enabled/50-mod-http-passenger.conf" ]; then
# 	executeExpression "$elevate ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf"
# fi
# executeExpression "cat /etc/nginx/conf.d/mod-http-passenger.conf"

# executeExpression "$elevate service nginx start"

# executeExpression "curl -s localhost | grep title"

# appName='blog'
# cat << EOF > ~/default
# server {
#   listen 80;
#   listen [::]:80;

#   server_name _;
#   root /home/deploy/${appName}/current/public;

#   passenger_enabled on;
#   passenger_app_env production;

#   location /cable {
#     passenger_app_group_name ${appName}_websocket;
#     passenger_force_max_concurrent_requests_per_process 0;
#   }

#   # Allow uploads up to 100MB in size
#   client_max_body_size 100m;

#   location ~ ^/(assets|packs) {
#     expires max;
#     gzip_static on;
#   }
# }
# EOF

# executeExpression "$elevate mv /etc/nginx/sites-enabled/default ~/default.old"
# executeExpression "$elevate cp ~/default /etc/nginx/sites-enabled/default"

# executeExpression "$elevate service nginx reload"

echo; echo "[$scriptName] --- end ---"
exit 0
