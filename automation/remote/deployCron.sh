#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# Check that Version has been passed
if [ -z "$1" ]; then
	echo "$scriptName : Version not supplied. HALT!"
	exit 1
fi

crontab -l > crontab.txt
CRON=$(cat crontab.txt)

MARKER="Build and Revision"

if [ -z "$CRON" ]; then
	
	if [[ "$OSTYPE" == "darwin"* ]]; then
		sed -i '' "s/"\%buildRevision\%"/$1/g" ./config/crontab.txt
	else
		sed -i "s/"\%buildRevision\%"/$1/g" ./config/crontab.txt
	fi

	CRON=$(cat ./config/crontab.txt)
	echo "$scriptName : No existing cron, install ..."
	echo "$scriptName : $CRON"
	crontab ./config/crontab.txt
else
	# Only deploy if the configuration is different
	NOMARKER=$(cat crontab.txt | grep "$MARKER")
	DELTA=$(diff -y --suppress-common-lines ./config/crontab.txt crontab.txt | grep -v "$MARKER")
	if [ ! -z "$DELTA" ] || [ -z "$NOMARKER" ]; then

		echo
		STAMP=$(date "+%Y-%m-%d_%T")
		mv crontab.txt crontab.txt-$STAMP
		sed -i "s/"\%buildRevision\%"/$1/g" ./config/crontab.txt
		echo "$scriptName : rename the existing config to crontab.txt-$STAMP"
		echo "                 ---- New Value ----                          |	              ---- Existing Value ----"
		diff -y --suppress-common-lines ./config/crontab.txt crontab.txt-$STAMP
		crontab ./config/crontab.txt
	else
		echo "$scriptName : No Update to cron required"
	fi
fi

