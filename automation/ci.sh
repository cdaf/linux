#!/usr/bin/env bash

# Entry point for branch based targetless CD
scriptName='ci.sh'

echo; echo "[     $scriptName     ] ============================================"
echo "[     $scriptName     ] Continuous Integration (CI) Process Starting"
echo "[     $scriptName     ] ============================================"
AUTOMATIONROOT="$( cd "$(dirname "$0")" && pwd )"
export CDAF_AUTOMATION_ROOT=$AUTOMATIONROOT

BUILDNUMBER="$1"
BRANCH="$2"
ACTION="$3"

$AUTOMATIONROOT/processor/buildPackage.sh "$BUILDNUMBER" "$BRANCH" "$ACTION"
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "[$scriptName] Exception! $AUTOMATIONROOT/processor/buildPackage.sh \"$BUILDNUMBER\" \"$BRANCH\" \"$ACTION\" returned $exitCode"
	exit $exitCode
fi
exit 0
