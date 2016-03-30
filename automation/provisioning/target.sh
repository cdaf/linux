#!/usr/bin/env bash
$scriptName = 'app.sh'

echo "$scriptName : --- start ---"
if [ -z "$1" ]; then
	group='deployer'
	echo "  group       : $group (default)"
else
	version="$1"
	echo "  group       : $group"
fi

if [ -z "$2" ]; then
	deployUser='deployer'
	echo "  deployUser  : $deployUser (deafult)"
else
	version="$2"
	echo "  deployUser  : $deployUser"
fi

if [ -z "$3" ]; then
	deployLand='/opt/packages/'
	echo "  deployLand  : $deployLand (deafult)"
else
	version="$3"
	echo "  deployLand  : $deployLand"
fi

# Update the deployer account to have access
sudo usermod -G $group $user
sudo mkdir -p $deployLand
sudo chown $user:$group $deployLand

echo "$scriptName : --- end ---"
