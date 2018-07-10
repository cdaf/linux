#!/usr/bin/env bash

# the file to be processed
filename=$1
if [ -z "$filename" ]; then
	echo "$0 : File not supplied"; exit 110
else
	if [ ! -f $filename ]; then
		echo "$0 : No existing file, ${filename}"; exit 111
	fi
fi

# the string to be replaced
name=$2
if [ -z "$name" ]; then
	echo "$0 : existing string not supplied"; exit 120
fi

# the new value
value=$3
if [ -z "$value" ]; then
	echo "$0 : new string not supplied"; exit 130
fi

# perform diff listing after
diff=$4
if [ -z "$diff" ]; then
	echo "$0 : difference listing not required"
else
	echo "$0 : difference listing requested"
	cp -f "${filename}" "/tmp/$(basename ${filename})"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
	sed -i '' "s^${name}^${value}^g" ${filename}
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : String replace in file failed, returned $exitCode"
		echo "$0 : sed -i '' \"s^${name}^${value}^g\" ${filename}"
		exit $exitCode
	fi
else
	sed -i "s^${name}^${value}^g" ${filename}
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : String replace in file failed, returned $exitCode"
		echo "$0 : sed -i \"s^${name}^${value}^g\" ${filename}"
		exit $exitCode
	fi
fi

diff --side-by-side "${filename}" "/tmp/$(basename ${filename})"
exit 0