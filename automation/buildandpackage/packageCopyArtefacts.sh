#!/usr/bin/env bash
set -e

# Arguments are not validated in sub-scripts, only at entry point
DRIVER=$1
WORK_DIR_DEFAULT=$2

if [ -f  "$DRIVER" ]; then
	echo; echo "$0 : Copy artifacts defined in $DRIVER"; echo
	config=$(cat ${DRIVER}) # cat will read all lines, native READ will miss lines that done have line-feed
	while read -r line; do

		#deleting lines starting with # ,blank lines ,lines with only spaces
		ARTIFACT=$(sed -e 's/#.*$//' -e '/^ *$/d' <<< $line)

		if [ ! -z $ARTIFACT ]; then
			# There must be a more elegant way to do this, but the current implementation is to overcome variable expansion when containing / character(s)
			declare -a artArray=${ARTIFACT};
			x=0
			unset source
			unset flat
			unset recurse
			unset copyParent
			for i in ${artArray[@]}; do 
				# First element in array is treated as the source
				if [ $x -eq 0 ]; then
					source=$(echo $i);
				else
					# options are case insensitive
					option=$(echo "$i" | tr '[a-z]' '[A-Z]')
					if [ "$option" == "-RECURSE" ]; then recurse="on"; fi
					if [ "$option" == "-FLAT" ]; then flat="on"; fi
				fi
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
				# Only set the target path for files, directories will be created as part of recursive copy
				if [ -d $source ]; then
					targetPath="$WORK_DIR_DEFAULT"
					# Copy the complete path into the target 				
					if [ "$recurse" == "on" ]; then
						copyParent="--parents "
					fi
				else
					targetPath="$WORK_DIR_DEFAULT/$(dirname "$source")/"
				fi
				# The target maybe a parent path of an existing artefact definition, so test for existing 
				if [ ! -d "$targetPath" ]; then
					mkdir -pv $targetPath
				fi
			fi
			cp $copyParent -av $source $targetPath
			exitCode=$?
			if [ $exitCode -ne 0 ]; then
				echo "$0 : cp -v ../$ARTIFACT . failed! Exit code = $exitCode."
				exit $exitCode
			fi
			
			artefactList=$(echo $artefactList ${ARTIFACT##*/})
		fi
		
	done < <(echo "$config")

	if [ -z "$artefactList" ]; then
		echo "$0 :   [WARN] No artefacts processed from definition file ($DRIVER)."
	fi
			
fi
