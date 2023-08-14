#!/usr/bin/env bash

scriptName='capabilities.sh'

version="$1"
if [[ "$version" != 'cdaf' ]]; then
	echo; echo "[$scriptName] --- start ---"
fi

AUTOMATIONROOT="$(dirname $( cd "$(dirname "$0")" ; pwd -P ))"
if [ -f "$AUTOMATIONROOT/CDAF.linux" ]; then
	check_file="$AUTOMATIONROOT/CDAF.linux"
else
	if [ -f "$CDAF_CORE/CDAF.properties" ]; then
		check_file="$CDAF_CORE/CDAF.properties"
	else
		if [ "$version" == 'cdaf' ]; then
			echo 'cannot determine'
			exit 0
		else
			echo "[$scriptName]   CDAF     : (cannot determine)"
		fi
	fi
fi

if [ ! -z "$check_file" ]; then
	productVersion=$(cat "$check_file" | grep productVersion)
	IFS='=' read -ra ADDR <<< $productVersion
	cdaf_version=${ADDR[1]}
	if [ "$version" == 'cdaf' ]; then
		echo "$cdaf_version"
		exit 0
	else
		echo "[$scriptName]   CDAF     : $cdaf_version"
	fi
fi

test="`hostname -f 2>&1`"
if [ $? -ne 0 ]; then
	echo "[$scriptName]   hostname : $(hostname)"
else
	echo "[$scriptName]   hostname : $test"
fi

echo "[$scriptName]   pwd      : $(pwd)"
echo "[$scriptName]   whoami   : $(whoami)"

echo
if [ -f '/etc/centos-release' ]; then
	echo "[$scriptName]   distro   : $(cat /etc/centos-release)"
else
	if [ -f '/etc/redhat-release' ]; then
		echo "[$scriptName]   distro   : $(cat /etc/redhat-release)"
	else
		test="`lsb_release --all 2>&1`"
		if [ $? -ne 0 ]; then
			if [ -f /etc/issue ]; then
				echo "[$scriptName]   distro   : $(cat /etc/issue)"
			else
				echo "[$scriptName]   distro   : $(uname -a)"
			fi
		else
			while IFS= read -r line; do
				if [[ "$line" == *"Description"* ]]; then
					IFS=' ' read -ra ADDR <<< $line
					echo "[$scriptName]   distro   : ${ADDR[1]} ${ADDR[2]}"
				fi
			done <<< "$test"
		fi	
	fi
fi

IFS=$'\n'
test="`ip a 2>&1`"
if [ $? -ne 0 ]; then
	test="`ifconfig 2>&1`"
	if [ $? -ne 0 ]; then
		test="`ipconfig 2>&1`" # MING
		if [ $? -ne 0 ]; then
			echo "[$scriptName]         ip : $(hostname -I)" # inside a container
		else
			ipconfig | grep IPv4
		fi
	else
		echo "[$scriptName]         ip : $test"
	fi
else
	test="`ip a | grep 'inet ' 2>&1`"
	for ip in $test; do
		IFS=' ' read -ra ADDR <<< $ip
		echo "[$scriptName]         ip : ${ADDR[1]}"
	done
fi
echo

if [ -f '/home/vagrant/linux-master/automation/CDAF.linux' ]; then
	test=$(cat /home/vagrant/linux-master/automation/CDAF.linux | grep productVersion)
	IFS='=' read -ra ADDR <<< $test
	test=${ADDR[1]}
	echo "[$scriptName] CDAF Box Version : $test"
fi

echo "[$scriptName] List 3rd party components"; echo

test="`git --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  git              : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	test=${ADDR[2]}
	echo "  git              : $test"
fi

test="`curl --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  curl             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  curl             : ${ADDR[1]}"
fi

test="`jq --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  jq               : (not installed)"
else
	IFS='-' read -ra ADDR <<< $test
	echo "  jq               : ${ADDR[1]}"
fi

# Java version lists to standard error
test="`java -version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  java             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	IFS='"' read -ra ADDR <<< ${ADDR[2]}
	echo "  java             : $(echo -e "${ADDR[@]}" | tr -d '[[:space:]]')"

	test="`javac -version 2>&1`"
	if [ $? -ne 0 ]; then
		echo "    javac          : (not installed)"
	else
		IFS=' ' read -ra ADDR <<< $test
		echo "    javac          : ${ADDR[1]}"
	fi
	
	# Ant version lists to standard error
	test="`ant -version 2>&1`"
	if [ $? -ne 0 ]; then
		echo "    ant            : (not installed)"
	else
		IFS=' ' read -ra ADDR <<< $test
		echo "    ant            : ${ADDR[3]}"
	fi
	
	test=$(mvn -version 2>&1)
	if [ $? -ne 0 ]; then
		echo "    mvn            : (not installed)"
	else
		IFS=' ' read -ra ADDR <<< $test
		echo "    mvn            : ${ADDR[2]}"
	fi
fi

test=$(docker --version 2>&1)
if [ $? -ne 0 ]; then
	echo "  docker           : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	IFS=',' read -ra ADDR <<< ${ADDR[2]}
	echo "  docker           : ${ADDR[0]}"

	test=$(docker-compose --version 2>&1)
	if [ $? -ne 0 ]; then
		echo "    docker-compose : (not installed)"
	else
		unset IFS
		read -ra ADDR <<< $test
		echo $test | grep , > /dev/null
		if [ $? -eq 0 ]; then
			IFS=',' read -ra ADDR <<< ${ADDR[2]}
			echo "    docker-compose : ${ADDR[0]}"
		else
			echo "    docker-compose : ${ADDR[3]}"
		fi
	fi
fi

test=$(terraform --version 2>&1)
if [ $? -ne 0 ]; then
	echo "  terraform        : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	IFS='v' read -ra ADDR <<< ${ADDR[1]}
	echo "  terraform        : ${ADDR[1]}"
fi

# Python version lists to standard error
test="`python --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  python           : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  python           : ${ADDR[1]}"
fi

# PIP version lists to standard error
test="`pip --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  pip              : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  pip              : ${ADDR[1]}"
fi

# Python version lists to standard error
test="`python3 --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  python3          : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  python3          : ${ADDR[1]}"

	# PIP version lists to standard error
	test="`pip3 --version 2>&1`"
	if [ $? -ne 0 ]; then
		echo "    pip3           : (not installed)"
	else
		IFS=' ' read -ra ADDR <<< $test
		echo "    pip3           : ${ADDR[1]}"
	fi
fi

# Ansible components
test=$(ansible-playbook --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  ansible-playbook : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  ansible-playbook : ${ADDR[-1]%]}"
fi

# Ruby
test="`ruby --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  ruby             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  ruby             : ${ADDR[1]}"
fi

# Puppet
test="`puppet --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  puppet           : (not installed)"
else
	echo "  puppet           : $test"
fi

# NodeJS components
test=$(node --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  NodeJS           : (not installed)"
else
	echo "  NodeJS           : ${test##*v}"

	# Node Package Manager
	test=$(npm -version 2>/dev/null)
	if [ -z "$test" ]; then
		echo "    NPM            : (not installed)"
	else
		echo "    NPM            : $test"
	fi

	# Postman CLI Collection Execution
	test=$(newman --version 2>/dev/null)
	if [ ! -z "$test" ]; then
		echo "    newman         : $test"
	fi

	# CloudFlare CLI
	test=$(wrangler -v 2>/dev/null)
	if [ ! -z "$test" ]; then
		echo "    wrangler       : $test"
	fi

	# process manager for Node.js
	test=$(pm2 --version 2>/dev/null)
	if [ ! -z "$test" ]; then
		echo "    pm2            : $test"
	fi

	# process manager for Node.js "nodemon reload, automatically"
	test=$(nodemon --version 2>/dev/null)
	if [ ! -z "$test" ]; then
		echo "    nodemon        : $test"
	fi
fi

# dotnet core
test=$(dotnet --version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  dotnet           : (not installed)"
else
	echo "  dotnet           : $test"
fi

# Kubectl is required for Helm
test=$(kubectl version --short=true --client=true 2>/dev/null)
if [ -z "$test" ]; then
	echo "  kubectl          : (not installed)"
else
	echo "  kubectl          : ${test##*v}"

	test=$(helm version --short 2>/dev/null)
	if [ -z "$test" ]; then
		echo "    helm           : (not installed)"
	else
		test="${test##*v}"
		echo "    helm           : ${test%+*}"
	fi
	
	test=$(helmsman -v 2>/dev/null)
	if [ -z "$test" ]; then
		echo "    helmsman       : (not installed)"
	else
		echo "    helmsman       : ${test##*v}"
	fi
fi

test=$(az version --output tsv 2>/dev/null)
unset IFS
read -ra ADDR <<< $test
if [ -z "$test" ]; then
	echo "  Azure CLI        : (not installed)"
else
	echo "  Azure CLI        : ${ADDR[0]}"

	test=$(az extension show --name azure-devops --output tsv 2>/dev/null)
	if [ ! -z "$test" ]; then
		unset IFS
		read -ra ADDR <<< $test
		echo "    ADO Extension  : ${ADDR[3]}"
	fi
fi

test=$(google-chrome -version 2>/dev/null)
if [ -z "$test" ]; then
	echo "  Chrome Browser   : (not installed)"
else
	read -ra ADDR <<< $test
	echo "  Chrome Browser   : ${ADDR[2]}"
fi

test=$(jp2a --version 2>&1)
if [ -z "$test" ]; then
	echo "  jp2a JPG 2 ASCII : (not installed)"
else
	read -ra ADDR <<< $test
	echo "  jp2a JPG 2 ASCII : ${ADDR[1]}"
fi

echo; echo "[$scriptName] --- end ---"; echo
