#!/usr/bin/env bash
scriptName=${0##*/}

function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "[$scriptName] Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

if [ "$#" -lt 2 ]; then
	echo "[$scriptName] Add a nodejs process to pm2, usage: $scriptName installDirectory entryPoint"
	echo "[$scriptName] Example ./$scriptName /opt/gateway server.js"
  exit 1
fi

echo "[$scriptName] --- start ---"
installDirectory="$1"
echo "[$scriptName]   installDirectory : $installDirectory"

entryPoint="$2"
echo "[$scriptName]   entryPoint       : $entryPoint"

name="$3"
if [ -z "$name" ]; then
	name="$entryPoint"
	echo "[$scriptName]   name             : $name (defaulted to entryPoint)"
else
	echo "[$scriptName]   name             : $name"
fi

if [ ! -f "${installDirectory}/${entryPoint}" ]; then
  echo "[$scriptName] entryPoint file non-existant [${installDirectory}/${entryPoint}]"
  exit 7785
fi

sh -c "cat <<'EOF' >${installDirectory}/${entryPoint}.json
{
\"name\":\"${name}\",
\"script\":\"${installDirectory}/${entryPoint}\",
\"cwd\":\"${installDirectory}\"
}
EOF"

echo
executeExpression "cat ${installDirectory}/${entryPoint}.json"

echo
executeExpression "pm2 reload ${installDirectory}/${entryPoint}.json"

echo
executeExpression "pm2 start ${installDirectory}/${entryPoint}.json --watch"

echo "[$scriptName] --- end ---"
exit 0
