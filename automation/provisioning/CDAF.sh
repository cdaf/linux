#!/usr/bin/env bash
set -e
scriptName='CDAF.sh'

echo "[$scriptName] --- start ---"

# Execute the CDAF emulation to verify
su vagrant << EOF
	cd /vagrant/
	./automation/cdEmulate.sh
EOF

# Clean the workspace
su vagrant << EOF
	cd /vagrant/
	./automation/cdEmulate.sh clean
EOF

echo "[$scriptName] --- end ---"
