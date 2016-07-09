#!/usr/bin/env bash
scriptName='installpm2.sh'
echo
echo "[$scriptName] : Install pm2 components"
echo

# snippet from http://unix.stackexchange.com/questions/18209/detect-init-system-using-the-shell
INIT=`sudo sh -c "ls -l /proc/1/exe"`
if [[ "$INIT" == *"systemd"* ]]; then
  SYSTEMINITDAEMON=systemd
fi
if [ -z "$SYSTEMINITDAEMON" ]; then
    echo "[$scriptName] :ERROR:Startup type untested: $SYSTEMINITDAEMON"
    exit 1
fi

sudo sh -c "npm install pm2@latest -g"
sudo sh -c "pm2 startup $SYSTEMINITDAEMON"

echo "[$scriptName] --- end ---"
exit 0