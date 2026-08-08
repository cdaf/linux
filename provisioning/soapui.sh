#!/usr/bin/env bash
# Usage:
#   ./soapui.sh                                    # latest release, default media cache
#   ./soapui.sh --version latest                    # latest release (explicit)
#   ./soapui.sh --version 5.9.1                      # specific version
#   ./soapui.sh --version v5.9.1                     # 'v' prefix also accepted
#   ./soapui.sh --media-cache /some/other/dir        # override cache dir
#   ./soapui.sh --version 5.9.1 --media-cache /tmp/x # both, in either order
#   ./soapui.sh --version=5.9.1 --media-cache=/tmp/x # '=' form also accepted
# Short forms: -v <version>  -m <mediaCache>

# Install (the latest package)
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/soapui.sh | bash -

# Install specific version
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/soapui.sh | bash -s -- --version 5.9.1

function executeExpression {
	echo "[$scriptName] $1"
	eval "$1"
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}
scriptName='soapui.sh'

echo "[$scriptName] --- start ---"

version=""
mediaCache=""

# Legacy support: if nothing looks like a flag (no arg starts with '-'),
# fall back to old positional form: ./soapui.sh <version> <mediaCache>
usesFlags=false
for arg in "$@"; do
	if [[ "$arg" == -* ]]; then
		usesFlags=true
		break
	fi
done

if [[ "$usesFlags" == false && $# -gt 0 ]]; then
	echo "[$scriptName] Positional arguments detected (legacy mode) — prefer --version/--media-cache going forward."
	version="$1"
	mediaCache="$2"
else
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--version=*)
				version="${1#*=}"
				shift
				;;
			--version|-v)
				version="$2"
				shift 2
				;;
			--media-cache=*)
				mediaCache="${1#*=}"
				shift
				;;
			--media-cache|-m)
				mediaCache="$2"
				shift 2
				;;
			-h|--help)
				echo "Usage: $scriptName [--version|-v <version>] [--media-cache|-m <dir>]"
				exit 0
				;;
			*)
				echo "[$scriptName] Unknown argument: $1" >&2
				exit 1
				;;
		esac
	done
fi

version="${version:-latest}"
if [[ "$version" == "latest" ]]; then
	echo "[$scriptName]   version    : $version (not supplied, set to ${version})"
	API_URL="https://api.github.com/repos/SmartBear/soapui/releases/${version}"
else
	echo "[$scriptName]   version    : $version"
	TAG="${version#v}"
	API_URL="https://api.github.com/repos/SmartBear/soapui/releases/tags/v${TAG}"
fi

if [ -z "$mediaCache" ]; then
	mediaCache='/.provision'
	echo "[$scriptName]   mediaCache : $mediaCache (default)"
else
	echo "[$scriptName]   mediaCache : $mediaCache"
fi

if [ $(whoami) != 'root' ];then
	elevate='sudo'
	echo "[$scriptName]   whoami     : $(whoami)"
else
	echo "[$scriptName]   whoami     : $(whoami) (elevation not required)"
fi

if [ ! -d "$mediaCache" ]; then
	executeExpression "mkdir $mediaCache"
fi

BODY=$(curl -fsSL "$API_URL")

# The actual binary links live inside the release notes body as plain
# markdown links to dl.eviware.com — they are not attached GitHub assets.
DL_URL=$(echo "$BODY" \
  | grep -oE 'https://dl\.eviware\.com/soapuios/[0-9.]+/SoapUI-[0-9.]+-linux-bin\.tar\.gz' \
  | head -n1)

if [[ -z "$DL_URL" ]]; then
  echo "[$scriptName] Could not find a linux-bin.tar.gz link for version '$version'." >&2
  echo "[$scriptName] Check available tags: https://github.com/SmartBear/soapui/tags" >&2
  exit 1
fi

# Derive filenames/paths from the resolved URL instead of hardcoding them
soapuiSource=$(basename "$DL_URL")                 # e.g. SoapUI-5.9.1-linux-bin.tar.gz
soapuiVersion=$(echo "$soapuiSource" | sed -E 's/^SoapUI-([0-9.]+)-linux-bin\.tar\.gz$/SoapUI-\1/')  # e.g. SoapUI-5.9.1
echo "[$scriptName]   resolved   : $soapuiSource"

if [ ! -f "${mediaCache}/${soapuiSource}" ]; then
	echo "[$scriptName] Media (${mediaCache}/${soapuiSource}) not found, attempting download ..."
	executeExpression "curl -s -o \"${mediaCache}/${soapuiSource}\" \"${DL_URL}\""
fi

executeExpression "cp \"${mediaCache}/${soapuiSource}\" ."
executeExpression "tar -xf $soapuiSource"
executeExpression "$elevate mv $soapuiVersion /opt/"

# Configure to directory on the default PATH
executeExpression "$elevate ln -s /opt/$soapuiVersion/ /opt/soapui"

echo "[$scriptName] --- end ---"
