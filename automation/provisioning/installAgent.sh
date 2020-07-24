#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  
scriptName='installAgent.sh'

echo "[$scriptName] --- start ---"
url="$1"
if [ -z "$url" ]; then
	echo "url not passed, HALT!"
	exit 101
else
	echo "[$scriptName]   url            : $url"
fi

pat="$2"
if [ -z "$pat" ]; then
	echo "pat not passed, HALT!"
	exit 102
else
	echo "[$scriptName]   pat            : \$pat"
fi

pool="$3"
if [ -z "$pool" ]; then
	pool='Default'
	echo "[$scriptName]   pool           : $pool (default)"
else
	echo "[$scriptName]   pool           : $pool"
fi

agentName="$4"
if [ -z "$agentName" ]; then
	agentName=$(hostname)
	echo "[$scriptName]   agentName      : $agentName (default)"
else
	echo "[$scriptName]   agentName      : $agentName"
fi

srvAccount="$5"
if [ -z "$srvAccount" ]; then
	srvAccount='vstsagent'
	echo "[$scriptName]   srvAccount     : $srvAccount (default)"
else
	echo "[$scriptName]   srvAccount     : $srvAccount"
fi

echo "[$scriptName]   hostname       : $(hostname)"
echo "[$scriptName]   pwd            : $(pwd)"
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami         : $(whoami)"
else
	echo "[$scriptName]   whoami         : $(whoami) (elevation not required)"
fi
version='2.172.2'
echo "[$scriptName]   version        : $version"

media="vsts-agent-linux-x64-${version}.tar.gz"

if [ -d './vso' ]; then
	executeExpression "$elevate rm -rf './vso'"
fi
if [ -d '/opt/vso' ]; then
	executeExpression "$elevate rm -rf '/opt/vso'"
fi
executeExpression "curl -s -O https://vstsagentpackage.azureedge.net/agent/${version}/${media}"
executeExpression "mkdir vso"
executeExpression "tar zxf ${media} -C ./vso"
executeExpression "$elevate cp -r vso /opt"
executeExpression "$elevate chown -R $srvAccount /opt/vso"
executeExpression "cd /opt/vso"
executeExpression "$elevate ./bin/installdependencies.sh"

# Must execute as non elevated user as config will exit with error if elevated
# Cannot indent or EOF is not detected
if [ $(whoami) != 'root' ];then
sudo su $srvAccount << EOF
	echo "[$scriptName] Switched from root to service account $srvAccount"
	echo "cd /opt/vso"
	cd /opt/vso
	echo "./config.sh --unattended --acceptTeeEula --url $url --auth pat --token **************** --pool \"$pool\" --agent \"$agentName\" --replace"
	./config.sh --unattended --acceptTeeEula --url $url --auth pat --token $pat --pool $pool --agent $agentName --replace
EOF
else
su $srvAccount << EOF
	echo "[$scriptName] Switched to service account $srvAccount"
	echo "cd /opt/vso"
	cd /opt/vso
	echo "./config.sh --unattended --acceptTeeEula --url $url --auth pat --token **************** --pool \"$pool\" --agent \"$agentName\" --replace"
	./config.sh --unattended --acceptTeeEula --url $url --auth pat --token $pat --pool "$pool" --agent "$agentName" --replace
EOF
fi

executeExpression "$elevate ./svc.sh install $srvAccount"

serviceName=($(systemctl list-unit-files | grep 'vsts.'))
executeExpression "sudo systemctl start $serviceName"
executeExpression "sudo systemctl status $serviceName"

echo "[$scriptName] --- end ---"
exit 0
