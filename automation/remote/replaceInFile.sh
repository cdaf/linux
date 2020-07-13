#!/usr/bin/env bash
scriptName=${0##*/}

# the file to be processed
filename=$1
if [ -z "$filename" ]; then
	echo "[$scriptName] File not supplied"; exit 110
else
	if [ ! -f $filename ]; then
		echo "[$scriptName] No existing file, ${filename}"; exit 111
	fi
fi

# the string to be replaced
name=$2
if [ -z "$name" ]; then
	echo "[$scriptName] existing string not supplied"; exit 120
fi

# the new value
value=$3
if [ -z "$value" ]; then
	echo "[$scriptName] new string not supplied"; exit 130
fi

# perform diff listing after
diff=$4
if [ -z "$diff" ]; then
	echo "[$scriptName] difference listing not required"
else
	echo "[$scriptName] difference listing requested"
	cp -f "${filename}" "/tmp/$(basename ${filename})"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
	sed -i '' "s^${name}^${value}^g" ${filename}
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] String replace in file failed, returned $exitCode"
		echo "[$scriptName] sed -i '' \"s^${name}^${value}^g\" ${filename}"
		exit $exitCode
	fi
else
	sed -i "s^${name}^${value}^g" ${filename}
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] String replace in file failed, returned $exitCode"
		echo "[$scriptName] sed -i \"s^${name}^${value}^g\" ${filename}"
		exit $exitCode
	fi
fi

diff --side-by-side "/tmp/$(basename ${filename})" "${filename}"
exit 0