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

function MASKED {
	CURRENT_IFS=$IFS
	IFS=$DEFAULT_IFS
	read -ra array <<< $(echo -n $1 | sha256sum)
	echo "${array[0]}" | tr '[:lower:]' '[:upper:]'
	IFS=$CURRENT_IFS
}

scriptName='installAgent.sh'

echo "[$scriptName] --- start ---"
url="$1"
if [ -z "$url" ]; then
	echo "[$scriptName]   url            : (not suppplied, install binaries and dependencies only)"
else
	echo "[$scriptName]   url            : $url"

	pat="$2"
	if [ -z "$pat" ]; then
		echo "pat not passed, HALT!"
		exit 102
	else
		echo "[$scriptName]   pat            : $(MASKED $pat) (SHA256 Mask)"
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
fi

srvAccount="$5"
if [ -z "$srvAccount" ]; then
	if [ -z "$ADO_AGENT_SERVICE_ACCOUNT" ]; then
		srvAccount='vstsagent'
		echo "[$scriptName]   srvAccount     : $srvAccount (default)"
	else
		srvAccount="$ADO_AGENT_SERVICE_ACCOUNT"
		echo "[$scriptName]   srvAccount     : $srvAccount (set from environment variable ADO_AGENT_SERVICE_ACCOUNT)"
	fi
else
	echo "[$scriptName]   srvAccount     : $srvAccount (Agent cannot be run installed as root)"
fi

version="$6"
if [ -z "$version" ]; then
	# from https://github.com/microsoft/azure-pipelines-agent/issues/3522	
	assets_url=$(curl -s "https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest" | grep assets_url)
	assets_url=$(echo "${assets_url#*:}")
	assets_url=$(echo "${assets_url%,}")
	assets_url=$(echo "${assets_url//\"/}")
	browser_download_url=$(curl -s $assets_url | grep browser_download_url)
	browser_download_url=$(echo "${browser_download_url#*v}")
	version=$(echo "${browser_download_url%/*}")
	echo "[$scriptName]   version        : $version (default)"
else
	echo "[$scriptName]   version        : $version"
fi

echo "[$scriptName]   hostname       = $(hostname)"
echo "[$scriptName]   pwd            = $(pwd)"
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami         = $(whoami)"
else
	echo "[$scriptName]   whoami         = $(whoami) (elevation not required)"
fi

export DEBIAN_FRONTEND=noninteractive
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

if [ -z "$url" ]; then
	echo "[$scriptName] URL not supplied, binary install only, exiting."
	echo "[$scriptName] --- end ---"
	exit 0
fi

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
	echo "[$scriptName][WARNING] Installing as $(whoami) returned exit code ${exitCode}, proceeding ..."
fi

echo "[$scriptName] Strip the hard-coded system name"
executeExpression "$elevate sed -i '/systemd-escape/d' /opt/vso/svc.sh"

org=$(echo ${url##*/})
org=$(echo ${org//-/})
org=$(echo ${org//_/})
serviceName="vsts.agent.${org}.service"
echo "[$scriptName] Trim hyphen and underscore from organisation name and register service ${serviceName}"
export SVC_NAME="${serviceName}"

executeExpression "$elevate ./svc.sh install $srvAccount"

executeExpression "$elevate systemctl start $serviceName"
executeExpression "$elevate systemctl status $serviceName --no-pager"

echo "[$scriptName] --- end ---"
exit 0
