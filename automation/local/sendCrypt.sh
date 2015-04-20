#!/usr/bin/env bash
set -e

# This script provides a repeatable deployment process. This uses two arguments, the target environment
# identifier and the $3 to deploy. Note: each $3 produced is expected to be uniquely identifiable.

if [ -z "$1" ]; then
	echo "$0 Environment Argument not passed. HALT!"
	exit 1
else
	ENVIRONMENT=$1
fi

if [ -z "$2" ]; then
	echo "$0 Build Argument not passed. HALT!"
	exit 2
else
	VERSION=$2
fi

if [ -z "$3" ]; then
	echo "$0 : Solution Name not supplied. HALT!"
	exit 3
else
	SOLUTION=$3
fi

if [ -z "$4" ]; then
	echo "$0 : Package Name not supplied. HALT!"
	exit 4
else
	DEPLOYUSER=$4
fi

if [ -z "$5" ]; then
	echo "$0 : Package Name not supplied. HALT!"
	exit 5
else
	DEPLOYHOST=$5
fi

if [ -z "$6" ]; then
	echo "$0 : Package Name not supplied. HALT!"
	exit 6
else
	DEPLOYLAND=$6
fi

if [ -z "$7" ]; then
	echo "$0 : Encrypted file directory not supplied. HALT!"
	exit 7
else
	CRYPTDIR=$7
fi


ls -L -1 $CRYPTDIR/$ENVIRONMENT* | xargs -n 1 basename > cryptFiles 2> /dev/null
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : No encrypted files (based on pattern $ENVIRONMENT*) found, no action required."
else
	
	while read cryptFile
	do
	
		echo
		echo "$0 : Copy encrypted file $cryptFile to extracted landing directory"
		scp $CRYPTDIR/$cryptFile $DEPLOYUSER@$DEPLOYHOST:$DEPLOYLAND/$SOLUTION-$VERSION
		exitCode=$?
		if [ "$exitCode" != "0" ]; then
			echo "$0 : scp $CRYPTDIR/$cryptFile $DEPLOYUSER@$DEPLOYHOST:$DEPLOYLAND/$SOLUTION-$VERSION failed! Returned $exitCode"
			exit $exitCode
		fi
	
	done < cryptFiles
		
fi

rm -f cryptFiles