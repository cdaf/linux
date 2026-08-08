#!/usr/bin/env bash
# Usage:
#   ./soapui.sh              # latest release
#   ./soapui.sh latest       # latest release (explicit)
#   ./soapui.sh 5.9.1        # specific version
#   ./soapui.sh v5.9.1       # 'v' prefix also accepted

# Install (the latest package)
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/soapui.sh | bash -

# Install specific version
# curl -s https://raw.githubusercontent.com/cdaf/linux/refs/heads/master/provisioning/soapui.sh | bash -s -- '5.9.1'

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

echo "[scriptName] : --- start ---"
version="${1:-latest}"
if [[ "$version" == "latest" ]]; then
	echo "[$scriptName]   version    : $version (not supplied, set to ${version})"
	API_URL="https://api.github.com/repos/SmartBear/soapui/releases/${version}"
else
	echo "[$scriptName]   version    : $version"
    TAG="${version#v}"
    API_URL="https://api.github.com/repos/SmartBear/soapui/releases/tags/v${TAG}"
fi

mediaCache="$2"
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
  echo "Could not find a linux-bin.tar.gz link for version '$VERSION'." >&2
  echo "Check available tags: https://github.com/SmartBear/soapui/tags" >&2
  exit 1
fi

if [ ! -f ${mediaCache}/${soapuiSource} ]; then
	echo "[$scriptName] Media (${mediaCache}/${soapuiSource}) not found, attempting download ..."
	executeExpression "curl -s -o ${mediaCache}/${soapuiSource} \"${DL_URL}\""
fi

executeExpression "cp \"${mediaCache}/${soapuiSource}\" ."
executeExpression "tar -xf $soapuiSource"
executeExpression "$elevate mv $soapuiVersion /opt/"

# Configure to directory on the default PATH
executeExpression "$elevate ln -s /opt/$soapuiVersion/ /opt/soapui"

echo "[scriptName] : --- end ---"
