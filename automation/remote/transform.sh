#!/usr/bin/env bash
set -e
scriptName=${0##*/}

# Read in two files, the definition file and template file, the name values in the
# definition file replace the tokens (substitution variables) in the template.
# If a tokenised file is not supplied, then simply return the name value pairs
# from the properties file, without new lines or comments.

if [ -z "$1" ]; then
	echo "$scriptName Properties File not passed. HALT!"
	exit 101
else
	PROPERTIES=$1
	if [ ! -f "$PROPERTIES" ]; then
		echo "$scriptName Properties File ($PROPERTIES) not found. HALT!"
		exit 102
	fi
fi

if [ ! -z "$2" ]; then
	TOKENISED=$2
	if [ ! -f "$TOKENISED" ]; then
		echo "$scriptName Tokenised File ($TOKENISED) not found. HALT!"
		exit 103
	fi
fi

if [ ! -z "$3" ]; then
	decryptedFileInMemory=$(gpg --decrypt --batch --passphrase $3 ${PROPERTIES})
	fileWithoutComments=$(sed -e 's/#.*$//' -e '/^ *$/d' <<< $decryptedFileInMemory)
else
	#deleting lines starting with # ,blank lines ,lines with only spaces
	fileWithoutComments=$(sed -e 's/#.*$//' -e '/^ *$/d' $PROPERTIES)
fi

while read -r LINE; do
	IFS="\="
	read -ra array <<< "$LINE"
	if [ -z "$TOKENISED" ]; then
		echo "  ${array[0]}=\"${array[1]}\""
	else		
		name="%${array[0]}%"
#		echo "[$scriptName] Replace $name with ${array[1]}"

		# Mac OSX sed 
		if [[ "$OSTYPE" == "darwin"* ]]; then
			sed -i '' "s^$name^${array[1]}^g" $TOKENISED
		else
			sed -i "s^$name^${array[1]}^g" $TOKENISED
		fi
	fi

done < <(echo "$fileWithoutComments")
