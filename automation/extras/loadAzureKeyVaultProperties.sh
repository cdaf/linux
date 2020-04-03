#!/usr/bin/env bash
set -e
scriptName='loadAzureKeyVaultProperties.sh'

echo "[$scriptName] --- Start ---"
secretsFile=$1
if [ ! -f "${secretsFile}" ]; then
	echo "[$scriptName][ERROR] Secrets file (${secretsFile}) not found!"
	echo "exit 1101"; exit 1101
else
	echo "[$scriptName]   secretsFile : $secretsFile"
fi

vaultName=$2
if [ -z "$vaultName" ]; then
	echo "[$scriptName] vaultName not passed. HALT!"
	echo "exit 1102"; exit 1102
else
	echo "[$scriptName]   vaultName   : $vaultName"
fi

outFile=$3
if [ -z "$outFile" ]; then
	echo "[$scriptName] outFile not passed. HALT!"
	echo "exit 1103"; exit 1103
else
	echo "[$scriptName]   outFile     : $outFile"
fi

echo "# Generated from $vaultName using $secretsFile" > $outFile
if [ -f "${secretsFile}" ]; then
	# GET authentication token for secret retrieval from metadata url
	token=$(curl -s -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net" | jq --raw-output '.access_token')
	if [ $token == 'null' ]; then
		curl -s -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net"; echo; echo
		echo "exit 1106"; exit 1106
	fi

	#deleting lines starting with # ,blank lines ,lines with only spaces
	fileWithoutComments=$(sed -e 's/#.*$//' -e '/^ *$/d' $secretsFile)
	
	while read -r LINE; do
		IFS="\="
		read -ra array <<< "$LINE"
		secret=$(curl -s -H "Authorization: Bearer $token" "https://${vaultName}.vault.azure.net/secrets/${array[1]}?api-version=2016-10-01" | jq --raw-output '.value')
		if [ $secret == 'null' ]; then
			echo "[$scriptName] Secret retrieval returned SecretNotFound for ${array[1]}!"
			echo "exit 1107"; exit 1104
		fi	
		echo "${array[0]}=${secret}" >> $outFile
	
	done < <(echo "$fileWithoutComments")
fi

echo "[$scriptName] --- End ---"
