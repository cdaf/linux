#!/usr/bin/env bash
set -e

# Read in two files, the definition file and template file, the name values in the
# defintion file replace values in the template, creating a new file.

# Check that the definition file is supplied
if [ -z "$1" ]; then
	echo "$0 : Definition File not passed. HALT!"
	exit 1
fi

# Check that the template file is supplied
if [ -z "$2" ]; then
	echo "$0 : Template File not passed. HALT!"
	exit 1
fi

# Check that the output file is supplied
if [ -z "$3" ]; then
	echo "$0 : Output File not passed. HALT!"
	exit 1
fi

while read LINE
do           
	IFS="\="
	read -ra array <<< "$LINE"
	name="${array[0]}"
	value="%${array[1]}%"
	echo "$0 : Replace $name with $value"
	cat $2 | sed "s/$name/$value/g" > $3
done < $1

exit 0
