#!/usr/bin/env bash
function executeExpression {
	counter=1
	max=5
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

scriptName='installGitLabRunner.sh'

echo "[$scriptName] --- start ---"
url="$1"
if [ -z "$url" ]; then
	echo "[$scriptName]   url      : (not supplied, registration will not be attempted)"
else
	echo "[$scriptName]   url      : $url"
fi

pat="$2"
if [ -z "$pat" ]; then
	echo "[$scriptName]   pat      : (not supplied, registration will not be attempted)"
else
	echo "[$scriptName]   pat      : \$pat"
fi

tags="$3"
if [ -z "$tags" ]; then
	tag=$(hostname)
	echo "[$scriptName]   tags     : $tags (default)"
else
	echo "[$scriptName]   tags     : $tags"
fi

name="$4"
if [ -z "$name" ]; then
	name=$(hostname)
	echo "[$scriptName]   name     : $name (default)"
else
	echo "[$scriptName]   name     : $name"
fi

executor="$5"
if [ -z "$executor" ]; then
	executor='shell'
	echo "[$scriptName]   executor : $executor (default)"
else
	echo "[$scriptName]   executor : $executor"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami   : $(whoami)"
else
	echo "[$scriptName]   whoami   : $(whoami) (elevation not required)"
fi

# Install from global repositories only supporting CentOS and Ubuntu
echo; echo "[$scriptName] Determine distribution (uname -a | grep el) ..."
uname -a
centos=$(uname -a | grep el)
if [ -z "$centos" ]; then
	echo "[$scriptName] Ubuntu/Debian, update repositories using apt-get"
	echo; echo "[$scriptName] Check that APT is available"
	dailyUpdate=$(ps -ef | grep  /usr/lib/apt/apt.systemd.daily | grep -v grep)
	if [ -n "${dailyUpdate}" ]; then
		echo
		echo "[$scriptName] ${dailyUpdate}"
		IFS=' ' read -ra ADDR <<< $dailyUpdate
		echo
		executeExpression "$elevate kill -9 ${ADDR[1]}"
		executeExpression "sleep 5"
	fi
	
	executeExpression "curl -s -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | $elevate bash"
	executeExpression "$elevate apt-get install -y gitlab-ci-multi-runner"

else
	echo "[$scriptName] CentOS/RHEL, update repositories using yum"
	echo "[$scriptName] $elevate yum check-update"; echo
	timeout=3
	count=0
	success='no'
	while [ $count -lt $timeout ]; do
		if [ elevate == 'sudo' ]; then
			sudo yum check-update
		else
			yum check-update
		fi
		exitCode=$?
		if [ $exitCode -eq 100 ] || [ $exitCode -eq 0 ]; then
			count=${timeout}
			success='yes'
		else
	   	    ((count++))
			echo "[$scriptName] yum sources update failed with exit code $exitCode, retry ${count}/${timeout} "
		fi
	done
	if [ "$success" != 'yes' ]; then
		echo "[$scriptName] yum sources failed to update after ${timeout} tries."
		echo "[$scriptName] Exiting with error code ${exitCode}"
		exit $exitCode
	fi
	executeExpression "curl -s -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.rpm.sh | $elevate bash"
	executeExpression "$elevate yum install -y gitlab-ci-multi-runner"
fi

if [ -z "$url" ] || [ -z "$pat" ]; then
	echo "[$scriptName] url ($url) or pat ($pat) were not supplied, registration skipped"
	echo "[$scriptName] Use the following to interactively register this runner..."
	echo; echo "$elevate gitlab-ci-multi-runner register"
else
	executeExpression '$elevate gitlab-runner register --non-interactive --url $url --registration-token $pat --name $name --executor $executor --tag-list "$tags"'
fi

echo; echo "[$scriptName] --- end ---"; echo
