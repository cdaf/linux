#!/usr/bin/env bash
set -e

# Check that Version has been passed
if [ -z "$1" ]; then
	echo "$0 : Version not supplied. HALT!"
	exit 1
fi

crontab -l > crontab.txt
CRON=$(cat crontab.txt)

MARKER="Datacom Build and Revision"

if [ -z "$CRON" ]; then
	sed -i "s/"\%buildRevision\%"/$1/g" ./config/crontab.txt
	CRON=$(cat ./config/crontab.txt)
	echo "$0 : No existing cron, install ..."
	echo "$0 : $CRON"
	crontab ./config/crontab.txt
else
	# Only deploy if the configuration is different
	NOMARKER=$(cat crontab.txt | grep "$MARKER")
	DELTA=$(diff -y --suppress-common-lines ./config/crontab.txt crontab.txt | grep -v "$MARKER")
	if [ -n "$DELTA" ] || [ -z "$NOMARKER" ]; then

		echo
		STAMP=$(date "+%Y-%m-%d_%T")
		mv crontab.txt crontab.txt-$STAMP
		sed -i "s/"\%buildRevision\%"/$1/g" ./config/crontab.txt
		echo "$0 : rename the existing config to crontab.txt-$STAMP"
		echo "                 ---- New Value ----                          |	              ---- Existing Value ----"
		diff -y --suppress-common-lines ./config/crontab.txt crontab.txt-$STAMP
		crontab ./config/crontab.txt
	else
		echo "$0 : No Update to cron required"
	fi
fi

