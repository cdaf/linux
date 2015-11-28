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
		unset source
		unset flat
		unset recurse
		for i in ${artArray[@]}; do 
			# First element in array is treated as the source
			if [ $x -eq 0 ]; then
				source=$(echo $i);
			else
				# options are case insensitive
				option=$(echo "$i" | tr '[a-z]' '[A-Z]')
			fi
			if [ "$option" == "-RECURSE" ]; then recurse="on"; fi
			if [ "$option" == "-FLAT" ]; then flat="on"; fi
			x=$((x + 1))
		done
		# In CDAF for Windows (PowerShell), recursive processing is explicitly  
 		# coded, in bash it is a native function, for consistency -recurse is looked for
 		# but no action performed, in the future I may support -recurse & -flat to allow a
  		# complete directory subtree flattening. 		
		if [ "$flat" == "on" ]; then
			targetPath="$WORK_DIR_DEFAULT"
			if [ -d "$source" ]; then
				source+="/*"
			fi
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
