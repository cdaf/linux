#!/usr/bin/env bash

# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/automation/remote/capabilities.sh | bash -
DEFAULT_IFS=$IFS
scriptName='capabilities.sh'

versionScript="$1"
if [ -z "$versionScript" ]; then
	echo; echo "[$scriptName] --- start ---"
fi

AUTOMATIONROOT="$(dirname $( cd "$(dirname "$0")" ; pwd -P ))"
if [ -f "$AUTOMATIONROOT/CDAF.linux" ]; then
	check_file="$AUTOMATIONROOT/CDAF.linux"
else
	if [ -f "$CDAF_CORE/CDAF.properties" ]; then
		check_file="$CDAF_CORE/CDAF.properties"
	fi
fi
if [ ! -z "$check_file" ]; then
	productVersion=$(cat "$check_file" | grep productVersion)
	IFS='=' read -ra ADDR <<< $productVersion
	cdaf_version=${ADDR[1]}
else
	cdaf_version='(cannot determine)'
fi

test=$(google-chrome -version 2>/dev/null)
if [ ! -z "$test" ]; then
	read -ra ADDR <<< $test
	chromeVersion="${ADDR[2]}"
	test=$(chromedriver -v 2>/dev/null)
	if [ ! -z "$test" ]; then
		read -ra ADDR <<< $test
		chromeDriverVersion=${ADDR[1]}
	fi

fi

if [ ! -z "$versionScript" ]; then
	if [ "$versionScript" == 'cdaf' ]; then
		echo "$cdaf_version"
		exit 0
	elif [ "$versionScript" == 'chrome' ]; then
		if [ ! -z "$chromeVersion" ]; then
			IFS='.' read -ra ADDR <<< $chromeVersion
			chromeVersion="${ADDR[0]}"
			if [ ! -z "$chromeDriverVersion" ]; then
				IFS='.' read -ra ADDR <<< $chromeDriverVersion
				chromeDriverVersion="${ADDR[0]}"
			else
				chromeDriverVersion='0'
			fi
			if [ "$chromeVersion" == "$chromeDriverVersion" ]; then
				echo "$chromeVersion"
				exit 0
			else
				echo "Chrome version $chromeVersion mismatch Chrome Driver version $chromeDriverVersion"
				exit 6822
			fi
		else
			echo 'chrome not installed'
			exit 6821
		fi
	else
		echo "Application check $versionScript not sdupported!"
		exit 6820
	fi
fi

echo "[$scriptName]   CDAF     : $cdaf_version"
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

test="`file --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  file             : (not installed)"
else
	IFS='-' read -ra ADDR <<< $test
	echo "  file             : ${ADDR[1]}"
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
	if [ $? -eq 0 ]; then
		unset IFS
		read -ra ADDR <<< $test
		echo $test | grep , > /dev/null
		if [ $? -eq 0 ]; then
			IFS=',' read -ra ADDR <<< ${ADDR[2]}
			echo "    docker-compose : ${ADDR[0]}"
		else
			echo "    docker-compose : ${test##*v}"
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

test=$(hugo version 2>&1)
if [ $? -ne 0 ]; then
	echo "  hugo             : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	IFS='v' read -ra ADDR <<< ${ADDR[1]}
	echo "  hugo             : ${ADDR[1]}"
fi

# Python version lists to standard error
test="`python --version 2>&1`"
if [ $? -ne 0 ]; then
	echo "  python           : (not installed)"
else
	IFS=' ' read -ra ADDR <<< $test
	echo "  python           : ${ADDR[1]}"

	# PIP version lists to standard error
	test="`pip --version 2>&1`"
	if [ $? -ne 0 ]; then
		echo "  pip              : (not installed)"
	else
		IFS=' ' read -ra ADDR <<< $test
		echo "  pip              : ${ADDR[1]}"
	fi
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
	if [ $? -eq 0 ]; then
		IFS=' ' read -ra ADDR <<< $test
		echo "    pip3           : ${ADDR[1]}"
	fi

	# PIP version lists to standard error
	test="`checkov --version 2>&1`"
	if [ $? -eq 0 ]; then
		echo "    checkov        : ${test}"
	fi
fi

# Ansible components
test=$(ansible-playbook --version 2>/dev/null)
if [ $? -ne 0 ]; then
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
if [ $? -ne 0 ]; then
	echo "  NodeJS           : (not installed)"
else
	echo "  NodeJS           : ${test##*v}"

	# Node Package Manager
	test=$(npm -version 2>/dev/null)
	if [ $? -eq 0 ]; then
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
if [ $? -ne 0 ]; then
	echo "  dotnet           : (not installed)"
else
	echo "  dotnet           : $test"
fi

# Kubectl is required for Helm
test=$(kubectl version --short=true --client=true 2>/dev/null)
if [ $? -ne 0 ]; then
	test=$(kubectl version --client=true 2>/dev/null)
	if [ $? -eq 0 ]; then
		kubetest=$(echo ${test#*v})
		kubetest=$(echo ${kubetest%% *})
	fi
else
	kubetest=$(echo ${test#*v})
	kubetest=$(echo ${kubetest%% *})
fi

if [ -z "$kubetest" ]; then
	echo "  kubectl          : (not installed)"
else
	echo "  kubectl          : $kubetest"

	test=$(helm version --short 2>/dev/null)
	if [ $? -eq 0 ]; then
		test="${test##*v}"
		echo "    helm           : ${test%+*}"
		IFS=$'\n'
		for line in $(helm plugin list); do
		    IFS=$DEFAULT_IFS read -ra array <<< "$line"
		    if [ "${array[0]}" != 'NAME' ]; then
				echo "      $line"
			fi
		done
		IFS=$DEFAULT_IFS
	fi
	
	test=$(helmsman -v 2>/dev/null)
	if [ $? -eq 0 ]; then
		echo "    helmsman       : ${test##*v}"
	fi

	test=$(helmfile --version 2>/dev/null)
	if [ $? -eq 0 ]; then
		echo "    helmfile       : ${test##* }"
	fi
fi

test=(`az version --output tsv 2>/dev/null`)
if [ $? -ne 0 ]; then
	echo "  Azure CLI        : (not installed)"
else
	echo "  Azure CLI        : ${test[0]}"

	test=(`az extension show --name azure-devops --output tsv 2>/dev/null`)
	if [ ! -z "$test" ]; then
		echo "    ADO Extension  : ${test[-1]}"
	fi
fi

test=(`aws --version 2> /dev/null`)
if [ $? -ne 0 ]; then
	echo "  AWS CLI          : (not installed)"
else
	echo "  AWS CLI          : ${test[0]##*/}"
fi

# AWS tools not dependent on AWS CLI
test=(`sam --version 2> /dev/null`)
if [ $? -eq 0 ]; then
	echo "    AWS SAM        : ${test[-1]}"
fi

export JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION=yes
test=(`cdk --version 2> /dev/null`)
if [ $? -eq 0 ]; then
	echo "    AWS CDK        : ${test}"
fi

if [ ! -z "$chromeVersion" ]; then
	echo "  Chrome Browser   : $chromeVersion"

	if [ ! -z "$chromeDriverVersion" ]; then
		echo "    Chrome Driver  : $chromeDriverVersion"
	fi
fi

test=$(jp2a --version 2>&1)
if [ $? -ne 0 ]; then
	echo "  jp2a JPG 2 ASCII : (not installed)"
else
	read -ra ADDR <<< $test
	echo "  jp2a JPG 2 ASCII : ${ADDR[1]}"
fi

echo; echo "[$scriptName] --- end ---"; echo
