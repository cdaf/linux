#!/usr/bin/env bash
scriptName=${0##*/}

echo; echo "[$scriptName] --- start ---"
# the file to be processed
filename=$1
if [ -z "$filename" ]; then
	echo "[$scriptName] File not supplied"; exit 110
else
	if [ ! -f $filename ]; then
		echo "[$scriptName] No existing file, ${filename}"; exit 111
	fi
	echo "[$scriptName] filename : $filename"
fi

# the string to be replaced
name=$2
if [ -z "$name" ]; then
	echo "[$scriptName] existing string not supplied"; exit 120
else
	echo "[$scriptName] name     : $name"
fi

# the new value
value=$3
if [ -z "$value" ]; then
	echo "[$scriptName] new string not supplied, existing lines will be deleted"
else
	echo "[$scriptName] value    : $value"
fi

# perform diff listing after
diff=$4
if [ -z "$diff" ]; then
	echo "[$scriptName] difference listing not required (choices yes or common)"
else
	echo "[$scriptName] diff     : $diff (choices yes or common)"
	cp -f "${filename}" "/tmp/$(basename ${filename})"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
	if [ -z "$value" ]; then
		sed -i '' "/${name}/d" ${filename}
	else
		sed -i '' "s^${name}^${value}^g" ${filename}
		exitCode=$?
		# Check execution normal, anything other than 0 is an exception
		if [ "$exitCode" != "0" ]; then
			echo "[$scriptName] String replace in file failed, returned $exitCode"
			echo "[$scriptName] sed -i '' \"s^${name}^${value}^g\" ${filename}"
			exit $exitCode
		fi
	fi
else
	if [ -z "$value" ]; then
		sed -i "/${name}/d" ${filename}
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
fi

if [ ! -z "$diff" ]; then
	if [ "$diff" == 'yes' ]; then
		diff --side-by-side --suppress-common-lines "/tmp/$(basename ${filename})" "${filename}"
	else
		diff --side-by-side "/tmp/$(basename ${filename})" "${filename}"
	fi
fi

echo; echo "[$scriptName] --- Finish ---"
exit 0