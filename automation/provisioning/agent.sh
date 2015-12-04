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
	echo "$0 : to use a non standard port, pass as deployer@localhost:<port>"
	echo
	exit 1
						
else
	
	# Process the argument, stripping out the port if passed
	sep=':'
	case $1 in
		(*"$sep"*)
			userHost=${1%%"$sep"*}
    	    port=${1#*"$sep"}
    	    ;;
		(*)
    	    userHost=$1
    	    port="22"
	    ;;
	esac
	
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
		ssh -p $port -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $userHost 'cat | bash /dev/stdin ' "$escapedKey REMOTE" < $0
	
		ssh -p $port -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $userHost 'cat | bash /dev/stdin ' "$userHost REMOTE TEST" < $0
				
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
			echo $userHost
			echo $userHost >> $HOME/.ssh/authorized_keys
	
		else # TEST REMOTE passed, so perform remote test
			
			echo
			echo "$0 +-----------------------+"
			echo "$0 | Executing remote test |"
			echo "$0 +-----------------------+"
			echo 	
			echo "$0 : If no password prompted for $userHost, test is successful"
			echo 	
		fi
	fi
fi
