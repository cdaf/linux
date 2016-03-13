#!/usr/bin/env bash
# set -e
# set -x

echo "buildserver.sh : --- start ---"

# Execute the CDAF emulation to verify
su vagrant << EOF
	cd /vagrant/
	./automation/cdEmulate.sh
EOF

echo "buildserver.sh : --- end ---"
