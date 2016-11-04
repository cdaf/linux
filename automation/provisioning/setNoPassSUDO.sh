#!/usr/bin/env bash

scriptName='setNoPassSUDO.sh'
echo
echo "[$scriptName] Set a user to have sudo access without password prompt"
echo
echo "[$scriptName] --- start ---"

username=$1
if [ -z "$username" ]; then
	username='deployer'
	echo "[$scriptName]   username     : $username (default)"
else
	echo "[$scriptName]   username     : $username"
fi

echo "[$scriptName] sudo sh -c \"echo \"$username ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers\""
sudo sh -c "echo \" \" >> /etc/sudoers"
sudo sh -c "echo \"# Added by CDAF\" >> /etc/sudoers"
sudo sh -c "echo \"$username ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers"

echo "[$scriptName] --- end ---"
