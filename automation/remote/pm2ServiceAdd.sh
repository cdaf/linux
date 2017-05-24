#!/usr/bin/env bash
scriptName='pm2ServiceAdd.sh'
echo
echo "[$scriptName] : Add a nodejs process to pm2, usage: [$scriptName][workingDirectory][nodejsprocess]"
echo "[$scriptName] : Example ./$scriptName /opt/gateway server.js"
echo

if [ "$#" -ne 2 ]; then
  echo "[$scriptName] :ERROR: must specify directory and nodejs file"
  exit 1
fi

workingDirectory="$1"
nodejsProcess="$2"

if [ ! -f "${workingDirectory}/${nodejsProcess}" ]; then
  echo "[$scriptName] :ERROR:nodejs file nonexistant [${workingDirectory}/${nodejsProcess}]"
  exit 1
fi

sh -c "cat <<'EOF' >${workingDirectory}/${nodejsProcess}.json
{
\"name\":\"${nodejsProcess}\",
\"script\":\"${workingDirectory}/${nodejsProcess}\",
\"CWD\":\"${workingDirectory}\"
}
EOF"

sh -c "pm2 start ${workingDirectory}/${nodejsProcess}.json --watch"

echo "[$scriptName] --- end ---"
exit 0
