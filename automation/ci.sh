#!/usr/bin/env bash

# Entry point for branch based targetless CD
scriptName='ci.sh'

# Arguments, positional BUILDNUMBER BRANCH ACTION LOCAL_WORK_DIR REMOTE_WORK_DIR are supported as well as named options
BUILDNUMBER=''
BRANCH=''
ACTION=''
LOCAL_WORK_DIR=''
REMOTE_WORK_DIR=''
HELP=''
parameterNames=(BUILDNUMBER BRANCH ACTION LOCAL_WORK_DIR REMOTE_WORK_DIR)
positionalArguments=()
namedParameters=()
while [ $# -gt 0 ]; do
	option=$(echo "$1" | tr '[A-Z]' '[a-z]')
	case "$option" in
		-help|--help)
			HELP='yes'
			;;
		-buildnumber|--buildnumber|-branch|--branch|-action|--action|-local_work_dir|--local_work_dir|-remote_work_dir|--remote_work_dir)
			if [ $# -lt 2 ] || [[ "$2" == -* ]]; then
				echo "[$scriptName][ERROR] Missing value for $1. Use -help for usage." >&2
				exit 2
			fi
			parameterName=$(echo "${option#-}" | tr '[a-z]' '[A-Z]')
			parameterName="${parameterName#-}"
			shift
			printf -v "$parameterName" '%s' "$1"
			namedParameters+=("$parameterName")
			;;
		--)
			shift
			positionalArguments+=("$@")
			break
			;;
		-*)
			echo "[$scriptName][ERROR] Unknown option $1. Use -help for usage." >&2
			exit 2
			;;
		*)
			positionalArguments+=("$1")
			;;
	esac
	shift
done

if [ -n "$HELP" ]; then
	echo
	echo "[$scriptName] Usage: $scriptName [[-BUILDNUMBER] <number>] [[-BRANCH] <branch>] [[-ACTION] <action>] [[-LOCAL_WORK_DIR] <dir>] [[-REMOTE_WORK_DIR] <dir>] [-help]"
	echo
	echo "  -BUILDNUMBER      Optional, positional (first argument). Defaults to a local counter."
	echo "  -BRANCH           Optional, positional (second argument). Defaults to feature."
	echo "  -ACTION           Optional, positional (third argument). One of:"
	echo "                      cionly       build and package only"
	echo "                      buildonly    build only"
	echo "                      packageonly  package only"
	echo "                      clean        clean build workspace"
	echo "                    When not supplied, build and package are both executed."
	echo "  -LOCAL_WORK_DIR   Optional, positional (fourth argument). Defaults to TasksLocal."
	echo "  -REMOTE_WORK_DIR  Optional, positional (fifth argument). Defaults to TasksRemote."
	echo "  Named options accept one or two leading dashes and are case-insensitive."
	echo "  Positional arguments fill parameters not supplied by name. Use -- to end options."
	echo "  -help             Display this message and exit."
	echo
	exit 0
fi

# Bind positional values to parameters not supplied by name, regardless of option order.
positionIndex=0
for parameterName in "${parameterNames[@]}"; do
	named=''
	for namedParameter in "${namedParameters[@]}"; do
		if [ "$parameterName" == "$namedParameter" ]; then named='yes'; break; fi
	done
	if [ -z "$named" ] && [ "$positionIndex" -lt "${#positionalArguments[@]}" ]; then
		printf -v "$parameterName" '%s' "${positionalArguments[$positionIndex]}"
		positionIndex=$((positionIndex + 1))
	fi
done
if [ "$positionIndex" -lt "${#positionalArguments[@]}" ]; then
	echo "[$scriptName][ERROR] Too many positional arguments. Use -help for usage." >&2
	exit 2
fi

echo; echo "[     $scriptName     ] ============================================"
echo "[     $scriptName     ] Continuous Integration (CI) Process Starting"
echo "[     $scriptName     ] ============================================"
export CDAF_COMMAND_SHELL='yes'
export AUTOMATIONROOT="$( cd "$(dirname "$0")" && pwd )"

"$AUTOMATIONROOT/processor/buildPackage.sh" "$BUILDNUMBER" "$BRANCH" "$ACTION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR"

exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "[$scriptName] Exception! \"$AUTOMATIONROOT/processor/buildPackage.sh\" \"$BUILDNUMBER\" \"$BRANCH\" \"$ACTION\" \"$LOCAL_WORK_DIR\" \"$REMOTE_WORK_DIR\" returned $exitCode"
	exit $exitCode
fi
exit 0
