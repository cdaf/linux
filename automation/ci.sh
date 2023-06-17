#!/usr/bin/env bash

# Entry point for branch based targetless CD
scriptName='ci.sh'

echo; echo "[     $scriptName     ] ============================================"
echo "[     $scriptName     ] Continuous Integration (CI) Process Starting"
echo "[     $scriptName     ] ============================================"
export AUTOMATIONROOT="$( cd "$(dirname "$0")" && pwd )"

BUILDNUMBER="$1"
BRANCH="$2"
ACTION="$3"
LOCAL_WORK_DIR="$4"
REMOTE_WORK_DIR="$5"

$AUTOMATIONROOT/processor/buildPackage.sh "$BUILDNUMBER" "$BRANCH" "$ACTION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR"

exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "[$scriptName] Exception! $AUTOMATIONROOT/processor/buildPackage.sh \"$BUILDNUMBER\" \"$BRANCH\" \"$ACTION\" \"$LOCAL_WORK_DIR\" \"$REMOTE_WORK_DIR\" returned $exitCode"
	exit $exitCode
fi
exit 0
