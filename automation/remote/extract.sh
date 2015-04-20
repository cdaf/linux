#!/usr/bin/env bash
set -e

# Extract the Delivered package
echo "extract.sh : Extract $1 to $2"
unzip -o $2/$1.zip -d $2/$1
