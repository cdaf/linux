#!/usr/bin/env bash
set -e
scriptName='CDAF.sh'

echo "[$scriptName] --- start ---"
echo "[$scriptName]   whoami     : $(whoami)"
runas="$1"
if [ -z "$runas" ]; then
	runas=$(whoami)
	echo "[$scriptName]   runas      : $runas (not supplied, run as current user)"
else
	echo "[$scriptName]   runas      : $runas"
fi

OPT_ARG="$2"
if [ -z "$OPT_ARG" ]; then
	echo "[$scriptName]   OPT_ARG    : (not supplied)"
else
	echo "[$scriptName]   OPT_ARG    : $OPT_ARG"
fi

echo
# Execute the CDAF emulation to verify
su $runas << EOF
	cd /vagrant/
	./automation/cdEmulate.sh $OPT_ARG
EOF

# Clean the workspace
su $runas << EOF
	cd /vagrant/
	./automation/cdEmulate.sh clean
EOF

echo "[$scriptName] --- end ---"
