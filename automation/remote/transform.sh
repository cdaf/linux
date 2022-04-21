#!/usr/bin/env bash
scriptName=${0##*/}

# Read in two files, the definition file and template file, the name values in the
# definition file replace the tokens (substitution variables) in the template.
# If a tokenised file is not supplied, then simply return the name value pairs
# from the properties file, without new lines or comments.

# Expand argument for variables within properties
function resolveContent {
	eval "echo $1"
}

# Return MD5 as uppercase Hexadecimal
function MD5MSK {
	CURRENT_IFS=$IFS
	IFS=$DEFAULT_IFS
	read -ra array <<< $(echo -n $1 | md5sum)
	echo "${array[0]}" | tr '[:lower:]' '[:upper:]'
	IFS=$CURRENT_IFS
}

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

if [ -z "$3" ]; then
	#deleting lines starting with # ,blank lines ,lines with only spaces
	fileWithoutComments=$(sed -e 's/#.*$//' -e '/^ *$/d' $PROPERTIES)
else
	decryptedFileInMemory=$(gpg --decrypt --batch --passphrase $3 ${PROPERTIES})
	fileWithoutComments=$(sed -e 's/#.*$//' -e '/^ *$/d' <<< $decryptedFileInMemory)
fi

while read -r LINE; do
    IFS="\=" read -r name value <<< "$LINE"
	if [ -z "$TOKENISED" ]; then
		# Cannot execute resolve/reveal logic here as there is only 1 output stream
		echo "  ${name}='${value}'"
	else
   	    name="%${name}%"
   	    grep -q ${name} ${TOKENISED}
   	    if [ $? -eq 0 ]; then
			if [[ "$propldAction" == "resolve" ]]; then
				echo "Found ${name}, replacing with ${value}"
				value=$(eval resolveContent "$value")
			elif [[ "$propldAction" == "reveal" ]]; then
				value=$(eval resolveContent "$value")
				echo "Found ${name}, replacing with ${value}"
			else
				if [ -z "$3" ]; then
					echo "Found ${name}, replacing with ${value}"
				else
					echo "Found ${name}, replacing with $(MD5MSK ${value}) (MD5 Mask)"
				fi
			fi
			
			# Mac OSX sed 
			if [[ "$OSTYPE" == "darwin"* ]]; then
				sed -i '' -- "s•${name}•${value}•g" ${TOKENISED}
			else
				sed -i -- "s•${name}•${value}•g" ${TOKENISED}
			fi
		else
			( exit 0 )
		fi
	fi
done < <(echo "$fileWithoutComments")
