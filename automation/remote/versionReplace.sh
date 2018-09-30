#!/usr/bin/env bash
#set -e
scriptName=${0##*/}

# Deploy folder structure is expect the source and target paths to be the same.
# Pass absolute path i.e. /etc/init.d/bonita
if [ -z "$1" ]; then
	echo "$scriptName : File not supplied, pass as absolute path i.e. /etc/init.d/bonita. HALT!"
	exit 1
else
	ABS_PATH=$1
fi

# Check that Version has been passed
if [ -z "$2" ]; then
	echo "$scriptName : Version not supplied. HALT!"
	exit 1
else
	BUILDNUMBER=$2
fi

MARKER="Build-Revision :"
NOMARKER=$(cat .$ABS_PATH | grep "$MARKER")
if [ -z "$NOMARKER" ]; then
	echo "$scriptName : Warning : Source file $ABS_PATH does not contain marker ($MARKER)."
fi

if [ ! -f $ABS_PATH ]; then
	echo "$scriptName : No existing file, create $ABS_PATH"
	# Mac OSX sed 
	if [[ "$OSTYPE" == "darwin"* ]]; then
		sed -i '' "s/"\%buildRevision\%"/$BUILDNUMBER/g" .$ABS_PATH
	else
		sed -i "s/"\%buildRevision\%"/$BUILDNUMBER/g" .$ABS_PATH
	fi
	cp .$ABS_PATH $ABS_PATH
else
	# Only deploy if the configuration is different, or if the existing file does not have version marker
	NOMARKER=$(cat $ABS_PATH | grep "$MARKER")
	DELTA=$(diff -y --suppress-common-lines .$ABS_PATH $ABS_PATH | grep -v "$MARKER")
	if [ -n "$DELTA" ] || [ -z "$NOMARKER" ]; then

		echo
		echo "Following changes apply to $ABS_PATH ..."
		STAMP=$(date "+%Y-%m-%d_%T")
		mv $ABS_PATH $ABS_PATH-$STAMP-$BUILDNUMBER
		
		# Mac OSX sed 
		if [[ "$OSTYPE" == "darwin"* ]]; then
			sed -i '' "s/"\%buildRevision\%"/$BUILDNUMBER/g" .$ABS_PATH
		else
			sed -i "s/"\%buildRevision\%"/$BUILDNUMBER/g" .$ABS_PATH
		fi
		
		echo "$scriptName : Updated $ABS_PATH to $BUILDNUMBER, existing file renamed to $ABS_PATH-$STAMP-$BUILDNUMBER"
		echo "               ---- New Value ----                      |               ---- Existing Value -----"
		diff -y --suppress-common-lines .$ABS_PATH $ABS_PATH-$STAMP-$BUILDNUMBER
		cp .$ABS_PATH $ABS_PATH
		echo

	else
		echo "$scriptName : No Update to $ABS_PATH required"
	fi
fi

