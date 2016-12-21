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

scriptName='installNodeJS.sh'
echo
echo "[$scriptName] --- start ---"
version="$1"
if [ -z "$version" ]; then
	version='6.9.2'
	echo "[$scriptName]   version        : $version (default)"
else
	echo "[$scriptName]   version        : $version"
fi

systemWide=$2
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

mediaCache="$3"
if [ -z "$mediaCache" ]; then
	mediaCache='/_provision'
	echo "[$scriptName]   mediaCache : $mediaCache (default)"
else
	echo "[$scriptName]   mediaCache : $mediaCache"
fi

runtime="node-v${version}-linux-x64"
mediaFullPath="${mediaCache}/${runtime}.tar.gz"

# Check for media
if [ -f "$mediaFullPath" ]; then
	echo "[$scriptName] Media found $mediaFullPath"
else
	echo "[$scriptName] Media not found, attempting download"
	if [ ! -d "$mediaCache" ]; then
		executeExpression "sudo mkdir -p $mediaCache"
	fi
	executeExpression "sudo curl -s -o $mediaFullPath http://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.gz"
fi

if [ "$systemWide" == 'yes' ]; then

	cd $mediaCache
	executeExpression "sudo tar -xzf node-v* -C /opt"

	# Set the environment settings (requires elevation), replace if existing
	echo "[$scriptName] echo export PATH=\"/opt/${runtime}/bin:$PATH\" > nodejs.sh"
	echo export PATH=\"/opt/${runtime}/bin:$PATH\" > nodejs.sh

	executeExpression "chmod +x nodejs.sh"
	executeExpression "sudo mv -v nodejs.sh /etc/profile.d/"

	# Execute the script to set the variable 
	executeExpression "source /etc/profile.d/nodejs.sh"

else

	executeExpression "curl https://raw.githubusercontent.com/creationix/nvm/v0.13.1/install.sh | bash"
	executeExpression "source ~/.bash_profile"
	executeExpression "nvm install v${version}"
	executeExpression "nvm alias default v${version}"
fi

echo "[$scriptName] Verify version"

node --version

echo "[$scriptName] --- end ---"
