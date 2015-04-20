#!/usr/bin/env bash
set -e

# Deploy folder structure is expect the source and target paths to be the same.
# Pass absolute path i.e. /etc/init.d/bonita
if [ -z "$1" ]; then
	echo "$0 : File not supplied, pass as absolute path i.e. /etc/init.d/bonita. HALT!"
	exit 1
fi

# Check that Version has been passed
if [ -z "$2" ]; then
	echo "$0 : Version not supplied. HALT!"
	exit 1
fi

MARKER="Build-Revision :"
NOMARKER=$(cat ..$1 | grep "$MARKER")
if [ -z "$NOMARKER" ]; then
	echo "$0 : Warning : Source file $1 does not contain marker ($MARKER)."
fi

if [ ! -f $1 ]; then
	echo "$0 : No existing file, create $1"
	sed -i "s/"\%buildRevision\%"/$2/g" ..$1
	cp ..$1 $1
else
	# Only deploy if the configuration is different, or if the existing file does not have version marker
	NOMARKER=$(cat $1 | grep "$MARKER")
	DELTA=$(diff -y --suppress-common-lines ..$1 $1 | grep -v "$MARKER")
	if [ -n "$DELTA" ] || [ -z "$NOMARKER" ]; then

		echo
		echo "Following changes apply to $1 ..."
		STAMP=$(date "+%Y-%m-%d_%T")
		mv $1 $1-$STAMP-$2
		sed -i "s/"\%buildRevision\%"/$2/g" ..$1
		echo "$0 : Updated $1 to $2, existing file renamed to $1-$STAMP-$2"
		echo "               ---- New Value ----                      |               ---- Existing Value -----"
		diff -y --suppress-common-lines ..$1 $1-$STAMP-$2
		cp ..$1 $1
	else
		echo "$0 : No Update to $1 required"
	fi
fi

