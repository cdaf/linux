#!/usr/bin/env bash
# custom script will exit on any error
set -e

# These are the standard argument set
SOLUTION="$1"
BUILDNUMBER="$2"
TARGET="$3"
echo
loadProperties="propertiesForLocalTasks/$TARGET"	
echo "$0 : PROPFILE : $loadProperties"
propertiesList=$(./transform.sh "$loadProperties")
printf "$propertiesList"
eval $propertiesList

echo "custom script testing compatible commands:"
echo whoami

echo "Argument 1 is :"
echo $1