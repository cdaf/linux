#!/usr/bin/env bash

echo "dns.sh : --- start ---"

# Version is set by the build process and is static for any given copy of this script
buildnumber="@buildnumber@"
echo "dns.sh : buildnumber : $buildnumber"

# Use hosts entries to provide DNS within the closed network
echo "Add app.skynet and buildserver.skynet to each others hosts file"
sudo sh -c 'echo "172.16.17.101 app.skynet" >> /etc/hosts'
sudo sh -c 'echo "172.16.17.102 buildserver.skynet" >> /etc/hosts'
 
echo "dns.sh : --- end ---"
