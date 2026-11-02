#!/usr/bin/env bash

function executeRetry {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
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

function executeYumCheck {
	counter=1
	max=5
	success='no'
	while [ "$success" != 'yes' ]; do
		echo "[$scriptName][$counter] $1"
		eval "$1"
		exitCode=$?
		# Exit 0 and 100 are both success
		if [ "$exitCode" == "100" ] || [ "$exitCode" == "0" ]; then
			success='yes'
		else
			counter=$((counter + 1))
			if [ "$counter" -le "$max" ]; then
				echo "[$scriptName] Failed with exit code ${exitCode}! Retrying $counter of ${max}"
			else
				echo "[$scriptName] Failed with exit code ${exitCode}! Max retries (${max}) reached."
				exit $exitCode
			fi					 
		fi
	done
}

function executeIgnore {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		if [ "$exitCode" == "1" ]; then
			echo "$0 : Warning: Returned $exitCode assuming already installed and continuing ..."
		else
			echo "$0 : Error! Returned $exitCode, exiting!"; exit $exitCode 
		fi
	fi
	return $exitCode
}

scriptName='installAnsible.sh'

function showHelp {
	printf '%s\n' \
		"Usage: $scriptName [yes|no] [version]" \
		"       $scriptName [-systemWide yes|no] [-version version] [-ansibleCore yes|no]" \
		"" \
		"  -systemWide yes|no  Install system-wide (default: yes), or for the current user." \
		"  -version version   Install the specified version (default: repository default)." \
		"  -ansibleCore yes|no Install ansible-core from PyPI in a virtual environment (default: no)." \
		"                     Uses /opt for system-wide installs, or the current user's home." \
		"  -help              Show this help and exit (also the default with no arguments)." \
		"" \
		"Named options may be supplied in any order. Positional values fill unset options."
}

if [ "$#" -eq 0 ]; then
	showHelp
	exit 0
fi

systemWide=''
version=''
ansibleCore='no'
systemWideSupplied='no'
versionSupplied='no'
while [ "$#" -gt 0 ]; do
	case "$1" in
		-help|--help|-h)
			showHelp
			exit 0
			;;
		-systemWide|--systemWide|-version|--version|-ansibleCore|--ansibleCore)
			if [ "$#" -lt 2 ] || [ -z "$2" ] || [[ "$2" == -* ]]; then
				echo "[$scriptName] $1 requires a value." >&2
				showHelp >&2
				exit 1
			fi
			case "$1" in
				-systemWide|--systemWide)
					systemWide=$2
					systemWideSupplied='yes'
					;;
				-version|--version)
					version=$2
					versionSupplied='yes'
					;;
				-ansibleCore|--ansibleCore)
					ansibleCore=$2
					;;
			esac
			shift 2
			;;
		-*)
			echo "[$scriptName] Unknown parameter: $1" >&2
			showHelp >&2
			exit 1
			;;
		*)
			if [ "$systemWideSupplied" == 'no' ]; then
				systemWide=$1
				systemWideSupplied='yes'
			elif [ "$versionSupplied" == 'no' ]; then
				version=$1
				versionSupplied='yes'
			else
				echo "[$scriptName] Unexpected argument: $1" >&2
				showHelp >&2
				exit 1
			fi
			shift
			;;
	esac
done

if [ "$ansibleCore" != 'yes' ] && [ "$ansibleCore" != 'no' ]; then
	echo "[$scriptName] -ansibleCore expects yes or no." >&2
	exit 1
fi

echo "[$scriptName] --- start ---"
if [ -z "$systemWide" ]; then
	systemWide='yes'
	echo "[$scriptName]   systemWide : $systemWide (default)"
else
	if [ "$systemWide" == 'yes' ] || [ "$systemWide" == 'no' ]; then
		echo "[$scriptName]   systemWide : $systemWide"
	else
		echo "[$scriptName] Expecting yes or no, exiting with error code 1"; exit 1
	fi
fi

if [ -z "$version" ]; then
	echo "[$scriptName]   version    : Not supplied, will use default"
else
	echo "[$scriptName]   version    : $version"
	export ansibleVersion="-${version}"
fi
if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

if [ -f '/etc/centos-release' ]; then
	distro=$(cat "/etc/centos-release")
	echo "[$scriptName]   distro     : $distro"
	fedora='yes'
else
	if [ -f '/etc/redhat-release' ]; then
		distro=$(cat "/etc/redhat-release")
		echo "[$scriptName]   distro     : $distro"
		fedora='yes'
	else
		debian='yes'
		test=$(lsb_release --all 2>&1)
		if [[ "$test" == *"not found"* ]]; then
			if [ -f "/etc/issue" ]; then
				distro=$(cat "/etc/issue")
				echo "[$scriptName]   distro     : $distro"
			else
				distro=$(uname -a)
				echo "[$scriptName]   distro     : $distro"
			fi
		else
			while IFS= read -r line; do
				if [[ "$line" == *"Description"* ]]; then
					IFS=' ' read -ra ADDR <<< $line
					distro=$(echo "${ADDR[1]} ${ADDR[2]}")
					echo "[$scriptName]   distro     : $distro"
				fi
			done <<< "$test"
			if [ -z "$distro" ]; then
				echo "[$scriptName] HALT! Unable to determine distribution!"; exit 774
			fi
		fi	
	fi
fi
echo

if [ "$fedora" == 'yes' ]; then
	IFS='.' read -ra ADDR <<< $distro
	distro=$(echo "${ADDR[0]##* }")
fi

if [ "$ansibleCore" == 'yes' ]; then
	if [ -z "$fedora" ]; then
		executeRetry "$elevate apt-get update"
		executeRetry "$elevate env DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv"
	elif [ "$distro" -gt 7 ]; then
		executeRetry "$elevate dnf install -y python3 python3-pip"
	else
		executeRetry "$elevate yum install -y python3 python3-pip"
	fi

	coreElevate=''
	if [ "$systemWide" == 'yes' ]; then
		coreEnvironment="/opt/ansible-core${ansibleVersion}"
		coreElevate=$elevate
	else
		coreEnvironment="$HOME/ansible-core${ansibleVersion}"
	fi
	corePackage='ansible-core'
	if [ -n "$version" ]; then
		corePackage="ansible-core==${version}"
	fi
	printf -v coreEnvironmentQuoted '%q' "$coreEnvironment"
	printf -v corePackageQuoted '%q' "$corePackage"
	executeRetry "$coreElevate python3 -m venv $coreEnvironmentQuoted"
	executeRetry "$coreElevate $coreEnvironmentQuoted/bin/python -m pip install $corePackageQuoted"
	if [ "$systemWide" == 'yes' ]; then
		executeRetry "$coreElevate mkdir -p /usr/local/bin"
		for coreCommand in "$coreEnvironment"/bin/ansible*; do
			printf -v coreCommandQuoted '%q' "$coreCommand"
			printf -v coreLinkQuoted '%q' "/usr/local/bin/${coreCommand##*/}"
			executeRetry "$coreElevate ln -sf $coreCommandQuoted $coreLinkQuoted"
		done
	else
		echo "[$scriptName] Activate this environment with: source $coreEnvironmentQuoted/bin/activate"
	fi
	export PATH="$coreEnvironment/bin:$PATH"
elif [ -z "$fedora" ]; then
	echo "[$scriptName] Debian/Ubuntu, update repositories using apt-get"
	echo
	echo "[$scriptName] Check that APT is available"
	dailyUpdate=$(ps -ef | grep  /usr/lib/apt/apt.systemd.daily | grep -v grep)
	if [ ! -z "${dailyUpdate}" ]; then
		echo
		echo "[$scriptName] ${dailyUpdate}"
		IFS=' ' read -ra ADDR <<< $dailyUpdate
		echo
		executeRetry "$elevate kill -9 ${ADDR[1]}"
		executeRetry "sleep 5"
	fi	
	
	echo "[$scriptName] $elevate apt-get update"
	echo
	timeout=3
	count=0
	while [ ${count} -lt ${timeout} ]; do
		$elevate apt-get update
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
	   	    ((count++))
			echo "[$scriptName] apt-get sources update failed with exit code $exitCode, retry ${count}/${timeout} "
		else
			count=${timeout}
		fi
	done
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] apt-get sources failed to update after ${timeout} tries."
		echo "[$scriptName] Exiting with error code ${exitCode}"
		exit $exitCode
	fi

	echo
	if [ "$systemWide" == 'yes' ]; then

		executeRetry "$elevate env DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common"
		executeRetry "$elevate apt-add-repository --yes --update ppa:ansible/ansible"
		executeRetry "$elevate apt-get update"

		if [ -z "$version" ]; then
			executeRetry "$elevate env DEBIAN_FRONTEND=noninteractive apt-get install -y ansible-core"
		else
			executeRetry "$elevate env DEBIAN_FRONTEND=noninteractive apt-get install -y ansible-core=${version}*"
		fi

	else
		executeRetry "$elevate apt-get update"
		executeRetry "$elevate env DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential libssl-dev libffi-dev python-dev"
	fi
	
else
	if [ $distro -gt 7 ]; then
		echo "[$scriptName] CentOS/RHEL, update repositories using DNF"
		executeRetry "$elevate dnf update -y"
		executeRetry "$elevate dnf install -y epel-release"
		executeRetry "$elevate dnf install -y ansible"
	else
		echo "[$scriptName] CentOS/RHEL, update repositories using yum"
		executeYumCheck "$elevate yum check-update"
		executeRetry "$elevate yum install -y gcc openssl-devel libffi-devel python-devel"
		if [ "$systemWide" == 'yes' ]; then
			if [ -z "$centos" ]; then # Red Hat Enterprise Linux (RHEL)
				echo "[$scriptName] Red Hat Enterprise Linux"
				version=$(cat /etc/redhat-release)
				IFS='.' read -ra arr <<< $version
				IFS=' ' read -ra arr <<< ${arr[0]}
				epelversion=$(echo ${arr[${#arr[@]} - 1]})
			    executeIgnore "$elevate yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${epelversion}.noarch.rpm" # Ignore if already installed
			else
				executeRetry "$elevate yum install -y epel-release"
			fi
			executeRetry "$elevate yum install -y ansible"
		fi
	fi
fi

if [ "$systemWide" == 'no' ] && [ "$ansibleCore" != 'yes' ]; then
	echo
	echo "[$scriptName] Install to current users ($(whoami)) home directory ($HOME)."
	echo
	# Distribution specific dependencies installed above, this process is generic for all distributions 
	executeRetry "$elevate pip install virtualenv virtualenvwrapper"
	executeRetry "source `which virtualenvwrapper.sh`"
	if [ ! -d ~/ansible${ansibleVersion} ]; then
		executeRetry "mkdir ~/ansible${ansibleVersion}"
		executeRetry "cd ~/ansible${ansibleVersion}"
		executeRetry "mkvirtualenv ansible${ansibleVersion}"
	else
		executeRetry "cd ~/ansible${ansibleVersion}"
	fi
	executeRetry "workon ansible${ansibleVersion}"
	if [ -z "$version" ]; then
		executeRetry "pip install ansible"
	else
		executeRetry "pip install ansible==${version}"
	fi
fi

if ! test=$(ansible-playbook --version 2>&1); then
	echo "[$scriptName] Ansible playbook version check failed: $test"; exit 99
elif [[ "$test" =~ ^ansible-playbook[[:space:]]+(\[core[[:space:]]+)?([0-9][[:alnum:].+-]*) ]]; then
	echo "[$scriptName] Ansible playbook version : ${BASH_REMATCH[2]}"
else
	echo "[$scriptName] Unable to determine Ansible playbook version: $test"; exit 99
fi	
echo 
echo "[$scriptName] --- end ---"
