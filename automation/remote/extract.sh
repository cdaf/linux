#!/usr/bin/env bash
set -e

echo
echo "$0 : Extract $1 to $2"
mkdir -p $2/$1
tar -zxvf $2/$1.tar.gz -C $2/$1
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : tar -zxvf $2/$1.tar.gz -C $2/$1 failed! Returned $exitCode"
	exit $exitCode
fi
