#!/usr/bin/env bash
set -e
scriptName='loadAzureKeyVaultEnvVars.sh'

echo "[$scriptName] --- Start ---"
TARGET=$1
if [ -z "$TARGET" ]; then
	echo "[$scriptName] TARGET not passed. HALT!"
	echo "exit 1101"; exit 1101
else
	echo "[$scriptName]   TARGET    : $TARGET"
fi

SECRETS="SECRET_${TARGET}"
if [ ! -f "${SECRETS}" ]; then
	echo "[$scriptName][WANR] TARGET File (${SECRETS}) not found."
else
	vaultName=$2
	if [ -z "$vaultName" ]; then
		echo "[$scriptName] vaultName not passed. HALT!"
		echo "exit 1102"; exit 1102
	else
		echo "[$scriptName]   vaultName : $vaultName"
	fi
fi

PROPERTIES="SETTING_${TARGET}"
if [ ! -f "${PROPERTIES}" ]; then
	echo "[$scriptName][WARN] TARGET File (${PROPERTIES}) not found."
else
	#deleting lines starting with # ,blank lines ,lines with only spaces
	fileWithoutComments=$(sed -e 's/#.*$//' -e '/^ *$/d' $PROPERTIES)
	
	while read -r LINE; do
		IFS="\="
		read -ra array <<< "$LINE"
		./setenv.sh "${array[0]}" "${array[1]}"
	
	done < <(echo "$fileWithoutComments")
fi

if [ -f "${SECRETS}" ]; then
	# GET authentication token for secret retrieval from metadata url
	token=$(curl -s -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net" | jq --raw-output '.access_token')
	if [ $token == 'null' ]; then
		curl -s -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net"; echo; echo
		echo "exit 1106"; exit 1106
	fi

	#deleting lines starting with # ,blank lines ,lines with only spaces
	fileWithoutComments=$(sed -e 's/#.*$//' -e '/^ *$/d' $SECRETS)
	
	while read -r LINE; do
		IFS="\="
		read -ra array <<< "$LINE"
		secret=$(curl -s -H "Authorization: Bearer $token" "https://${vaultName}.vault.azure.net/secrets/${array[1]}?api-version=2016-10-01" | jq --raw-output '.value')
		if [ $secret == 'null' ]; then
			echo "[$scriptName] Secret retrieval returned SecretNotFound for ${array[1]}!"
			echo "exit 1107"; exit 1104
		fi	
		./setenv.sh "${array[0]}" "${secret}" "machine" "yes"
	
	done < <(echo "$fileWithoutComments")
fi

echo "[$scriptName] --- End ---"
