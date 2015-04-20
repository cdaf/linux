#!/usr/bin/env bash
set -e

# When the script calls itself remotely, it passes the REMOTE as 
# a second argument, the first argument is not assigned to a 
# named variable becuase it has different meanings depending on 
# how it has been called 
REMOTE=$2
TEST=$3

if [ -z "$1" ]; then
	
	echo
	echo "$0 : Remote user and host not supplied, i.e. deployer@localhost"
	echo
	exit 1
						
else
	if [ -z "$REMOTE" ]; then # not remote, so launch local processes
		
		echo
		echo "$0 +-----------------------+"
		echo "$0 | Executing local steps |"
		echo "$0 +-----------------------+"
		echo
		if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
			echo "$0 : Generate users public and private key"
			ssh-keygen -t rsa
		fi
		
		publicKey=$(cat $HOME/.ssh/id_rsa.pub)
		echo "$0 : $publicKey"
		printf '%q\n' "$publicKey"
		escapedKey=$(printf '%q\n' "$publicKey")
		echo "$0 : $escapedKey"
		
		# push the same file back at the target
		echo
		ssh $1 'cat | bash /dev/stdin ' "$escapedKey REMOTE" < $0
	
		ssh $1 'cat | bash /dev/stdin ' "$1 REMOTE TEST" < $0
				
	else
		if [ -z "$TEST" ]; then # not test, so perform remote processes
	
			echo
			echo "$0 +------------------------+"
			echo "$0 | Executing remote steps |"
			echo "$0 +------------------------+"
			echo 	
	
			if [ ! -d "$HOME/.ssh" ]; then
				echo "$0 : Create $HOME/.ssh"
				mkdir $HOME/.ssh
				chmod 700 $HOME/.ssh
			fi
			
			if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
				echo "$0 : Create $HOME/.ssh/authorized_keys"
				touch $HOME/.ssh/authorized_keys
				chmod 600 $HOME/.ssh/authorized_keys
			fi
		
			echo
			echo Append the users public key to the remote hosts authorized_keys
			echo
			echo $1
			echo $1 >> $HOME/.ssh/authorized_keys
	
		else # TEST REMOTE passed, so perform remote test
			
			echo
			echo "$0 +-----------------------+"
			echo "$0 | Executing remote test |"
			echo "$0 +-----------------------+"
			echo 	
			echo "$0 : If no password prompted for $1, test is successful"
			echo 	
		fi
	fi
fi
