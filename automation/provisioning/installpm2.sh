#!/usr/bin/env bash

function executeRetry {
	counter=1
	max=3
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$counter] $1"
		eval "$1"
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

scriptName='installpm2.sh'
echo; echo "[$scriptName] PM2, Process Manager for Node.js. No arguments supported. Requires Node and NPM."; echo
echo "[$scriptName] --- start ---"
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami : $(whoami)"
else
	echo "[$scriptName]   whoami : $(whoami) (elevation not required)"
fi

test="`npm -v 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	echo "[$scriptName] Install Error! NPM verification failed."
	exit 1937
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[0]}
	echo "[$scriptName]   NPM    : $test"
fi	

# snippet from http://unix.stackexchange.com/questions/18209/detect-init-system-using-the-shell
if [ -z $elevate ]; then
	INIT=`sh -c "ls -l /proc/1/exe"`
else
	INIT=`sudo sh -c "ls -l /proc/1/exe"`
fi
if [[ "$INIT" == *"systemd"* ]]; then
  SYSTEMINITDAEMON=systemd
fi
if [ -z "$SYSTEMINITDAEMON" ]; then
    echo "[$scriptName] :ERROR:Startup type untested: $SYSTEMINITDAEMON"
    exit 1938
fi

echo; echo "[$scriptName] Source all user profile start scripts"; echo
if [ -z $elevate ]; then
	sh -c 'for startScript in $(find /etc/profile.d -type f -name *.sh); do . $startScript ;echo $startScript; done'
else
	sudo sh -c 'for startScript in $(find /etc/profile.d -type f -name *.sh); do . $startScript ;echo $startScript; done'
fi

echo; echo "[$scriptName] Install PM2"; echo
executeRetry "$elevate npm install pm2@latest -g"

if [ ! -f "/usr/bin/node" ]; then
	executeRetry "$elevate ln -s /usr/bin/nodejs /usr/bin/node"
fi
executeRetry "$elevate pm2 startup $SYSTEMINITDAEMON"

echo; echo "[$scriptName] --- end ---"; echo
exit 0
