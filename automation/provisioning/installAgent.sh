#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName][ERROR] $EXECUTABLESCRIPT returned $exitCode"
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
	echo "[$scriptName]   pool           : $pool (default, use pool name with '@' for Project@Deployment Group)"
else
	echo "[$scriptName]   pool           : $pool (use pool name with '@' for Project@Deployment Group)"
fi

agentName="$4"
if [ -z "$agentName" ]; then
	agentName=$(hostname)
	agentName=${agentName//-}
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
version='2.150.3'
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

if [[ "$pool" == *"@"* ]]; then
	IFS='@' read -ra arr <<< $pool
	project=${arr[0]}
	group=${arr[1]}
	echo "[$scriptName]   project        : $project"
	echo "[$scriptName]   group          : $group"
	command="./config.sh --unattended --acceptTeeEula --url '$url' --auth pat --token $pat --deploymentgroup --deploymentgroupname '$group' --projectname '$project' --agent '$agentName' --replace"
	listing="./config.sh --unattended --acceptTeeEula --url '$url' --auth pat --token ************** --deploymentgroup --deploymentgroupname '$group' --projectname '$project' --agent '$agentName' --replace"
else
	command="./config.sh --unattended --acceptTeeEula --url '$url' --auth pat --token $pat --pool '$pool' --agent '$agentName' --replace"
	listing="./config.sh --unattended --acceptTeeEula --url '$url' --auth pat --token ************** --pool '$pool' --agent '$agentName' --replace"
fi

if ! [ -z "$http_proxy" ]; then
	command+=" --proxyurl '$http_proxy'"
	listing+=" --proxyurl '$http_proxy'"
fi

# Must execute as non elevated user as config will exit with error if elevated
# Cannot indent EOF or it will not be detected
if [ $(whoami) != 'root' ];then
	sudo su $srvAccount << EOF
	echo "[$scriptName] Switched from root to service account $srvAccount"
	echo "cd /opt/vso"
	cd /opt/vso
	echo "$listing"
	eval "$command"
	exitCode=$?
	if [ "\$exitCode" != "0" ]; then
		echo "[$scriptName][ERROR] \$listing returned \$exitCode"
		exit \$exitCode
	fi
EOF

else
	su $srvAccount << EOF
	echo "[$scriptName] Installing as service account $srvAccount"
	echo "cd /opt/vso"
	cd /opt/vso
	echo "$listing"
	eval "$command"
	exitCode=$?
	if [ "\$exitCode" != "0" ]; then
		echo "[$scriptName][ERROR] \$listing returned \$exitCode"
		exit \$exitCode
	fi
EOF

fi

exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "[$scriptName][ERROR] $(whoami) failure. $exitCode"
	exit $exitCode
fi

executeExpression "$elevate ./svc.sh install $srvAccount"

serviceName=($(systemctl list-unit-files | grep 'vsts.'))
executeExpression "sudo systemctl start $serviceName"
executeExpression "sudo systemctl status $serviceName"

echo "[$scriptName] --- end ---"
exit 0
