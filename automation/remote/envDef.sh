#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# Elevated (sudo) call from Deploy

DEFINITION="ENVIR_DEF=\"$1\""
echo "[$scriptName] Add $DEFINITION to /etc/environment"
echo $DEFINITION >> /etc/environment

