#!/usr/bin/env bash
set -e

# Arguments are not validated in sub-scripts, only at entry point
DRIVER=$1
WORK_DIR_DEFAULT=$2

if [ -f  "$DRIVER" ]; then
	echo
	echo "$0 : Copy artifacts defined in $DRIVER"
	echo
	#deleting lines starting with # ,blank lines ,lines with only spaces
	sed -e 's/#.*$//' -e '/^ *$/d' $DRIVER > fileWithoutComments
			
	while read ARTIFACT; do

		# There must be a more elegant way to do this, but the current implementation is to 
		# overcome variable expansion when containing / character(s)
		declare -a artArray=${ARTIFACT};
		x=0
		source=""
		flat=""
		recurse=""
		for i in ${artArray[@]}; do 
			if [ $x -eq 0 ]; then source=$(echo $i); fi
			if [ "$i" == "-Recurse" ]; then recurse="on"; fi
			if [ "$i" == "-Flat" ]; then flat="on"; fi
			x=$((x + 1))
		done

		# when set to -Recursive copy, retain the source path as sub-directory of the target
		# this is ignored if -Flat is set. In Windows (PowerShell), recursive processing is 
 		# coded, in bash it is not, the support for -Flat is included for consistency 		
		if [ -z $recurse ] || [ ! -z $flat ]; then
			targetPath="$WORK_DIR_DEFAULT"
		else
			targetPath="$WORK_DIR_DEFAULT/$(dirname "$source")/"
			if [ ! -d "$targetPath" ]; then
				mkdir -pv $targetPath
			fi 
		fi
		cp -av $source $targetPath
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo "$0 : cp -v ../$ARTIFACT . failed! Exit code = $exitCode."
			exit $exitCode
		fi
		
		artefactList=$(echo $artefactList ${ARTIFACT##*/})
		
	done < fileWithoutComments
	
	rm fileWithoutComments

	if [ -z "$artefactList" ]; then
		echo
		echo "$0 : No artefacts processed from definition file ($DRIVER), if this is unexpected, check for missing line feed or DOS carriage return."
	fi
			
fi
