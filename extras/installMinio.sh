#!/usr/bin/env bash
function executeExpression {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}

function executeIgnore {
	echo "$1"
	eval $1
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Warning! $EXECUTABLESCRIPT returned $exitCode"
	fi
}

scriptName='installMinio.sh'

echo; echo "[$scriptName] --- start ---"
range="$1"
if [ -z "$range" ]; then
	echo "[$scriptName]   range  : (not passed, will run stand-alone)"
else
	echo "[$scriptName]   range  : $range (distributed)"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami : $(whoami)"
else
	echo "[$scriptName]   whoami : $(whoami) (elevation not required)"
fi

if [ -d './automation' ]; then
	atomicPath='.'
else
	echo "[$scriptName] Provisioning directory (./automation) not found in workspace, looking for alternative ..."
	if [ -d '/vagrant/automation' ]; then
		atomicPath='/vagrant'
	else
		echo "[$scriptName] $atomicPath not found for either Docker or Vagrant, will download latest"
		executeExpression "curl -s -O http://cdaf.io/static/app/downloads/LU-CDAF.tar.gz"
		executeExpression "tar -xzf LU-CDAF.tar.gz"
		atomicPath='.'
	fi
fi
echo "[$scriptName] Using atomicPath $atomicPath"

echo
test="`curl --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] curl not installed, required to download, install using package manager ..."
	executeExpression "$atomicPath/automation/provisioning/base.sh curl"
	executeExpression "curl --version"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] curl : $test"
fi	

echo;echo "[$scriptName] Fetching Minio ...";echo
executeExpression "curl -sSL https://dl.min.io/server/minio/release/linux-amd64/minio -o /opt/minio/minio"
executeExpression "$elevate chown -R minio:minio /opt/minio"
executeExpression "$elevate chmod +x /opt/minio/minio"

echo;echo "[$scriptName] set /etc/systemd/system/minio-server.service ...";echo

(
cat <<-EOF
[Unit]
Description="Minio server"
Documentation=https://docs.min.io/
Requires=network-online.target
After=network-online.target

[Service]
User=minio
ExecStart=/opt/minio/minio server /var/object-data-store

[Install]
WantedBy=multi-user.target
EOF
) | sudo tee /etc/systemd/system/minio-server.service

executeExpression "cat /etc/systemd/system/minio-server.service"
executeExpression "$elevate systemctl enable minio-server.service"
executeExpression "$elevate systemctl start minio-server"
executeExpression "sleep 5"
executeExpression "$elevate systemctl status minio-server"

echo; echo "[$scriptName] --- end ---"; echo
