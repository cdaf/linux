#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
	echo "$0 : Directory not supplied, pass as absolute path i.e. /etc/init.d/bonita. HALT!"
	exit 1
fi

if [ -z "$2" ]; then
	echo "$0 : Version not supplied. HALT!"
	exit 1
fi

if [ -z "$2" ]; then
	echo "$0 : Mask not supplied, *.* for all. HALT!"
	exit 1
fi

echo "$0 : Processing directory $1 (only differences will be reported ...)"
ls -L -1 ..$1/$3 | xargs -n 1 basename > FILE_LIST

while read LINE
do           
	if [ ! -f $1/$LINE ]; then
		echo "$0 : No existing file, create $1/$LINE"
		cp ..$1/$LINE $1/$LINE
	else
		# Only deploy if files are different
		DELTA=$(diff ..$1/$LINE $1/$LINE)
		if [ -n "$DELTA" ]; then
			echo "$0 : $DELTA"
			STAMP=$(date "+%Y-%m-%d_%T")
			mv $1/$LINE $1/$LINE-$STAMP-$2
			echo "$0 : rename the existing file to $1/$LINE-$STAMP-$2 and update"
			cp ..$1/$LINE $1/$LINE
		fi
	fi
done < FILE_LIST
