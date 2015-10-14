#!/bin/bash
# Emulate calling the package and deploy process as it would be from the automation toolset, 
# e.g. Bamboo or Jenkings, replacing buildNumber with timestamp
# workspace with temp space. The variables provided in Jenkins are emulated in the scripts
# themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

# Check Action
ACTION="$1"

scriptName=${0##*/}

echo
echo "$scriptName : --------------------"
echo "$scriptName : Initialise Emulation"
echo "$scriptName : --------------------"
echo "$scriptName :   ACTION              : $ACTION"

# Framework structure
automationRoot="automation"
automationHelper="$automationRoot/remote"
workDirLocal="TasksLocal"
workDirRemote="TasksRemote"

# Build and Delivery Properties Lookup values
environmentBuild="BUILD"
environmentDelivery="DEV"
echo "$scriptName :   environmentBuild    : $environmentBuild"
echo "$scriptName :   environmentDelivery : $environmentDelivery"

# Use timestamp to ensure unique build number and emulate the revision ID (source control) 
# CDM-98 reduce the build number to an 10 digit integer
buildNumber=$(date "+%m%d%H%M%S")
revision="55"
echo "$scriptName :   buildNumber         : $buildNumber"
echo "$scriptName :   revision            : $revision"

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "$scriptName :   solutionRoot        : "
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.solution" ]; then
		solutionRoot="$directoryName"
	fi
done
if [ -z "$solutionRoot" ]; then
	solutionRoot="$automationRoot/solution"
	echo "$solutionRoot (default, project directory containing CDAF.solution not found)"
else
	echo "$solutionRoot (override $solutionRoot/CDAF.solution found)"
fi

# Check for customised CI process
printf "$scriptName :   ciProcess           : "
if [ -f "$solutionRoot/cdEmulate-ci.sh" ]; then
	cdProcess="$solutionRoot/cdEmulate-ci.sh"
	echo "$ciProcess (override)"
else
	ciProcess="$automationRoot/emulator/cdEmulate-ci.sh"
	echo "$ciProcess (default)"
fi

# Check for customised Delivery process
printf "$scriptName :   cdProcess           : "
if [ -f "$solutionRoot/cdEmulate-deliver.sh" ]; then
	cdProcess="$solutionRoot/cdEmulate-deliver.sh"
	echo "$cdProcess (override)"
else
	cdProcess="$automationRoot/emulator/cdEmulate-deliver.sh"
	echo "$cdProcess (default)"
fi

# If a solution properties file exists, load the properties
if [ -f "$solutionRoot/CDAF.solution" ]; then
	echo
	echo "$scriptName : Load Solution Properties $solutionRoot/CDAF.solution"
	propertiesList=$($automationHelper/transform.sh "$solutionRoot/CDAF.solution")
	echo "$propertiesList"
	eval $propertiesList
fi

# CDM-70 : If the Solution is not defined in the CDAF.solution file, use current working directory
# In Jenkins parameter is JOB_NAME 
if [ -z "$solutionName" ]; then
	solutionName=$(basename $(pwd))
	echo
	echo "$scriptName : Solution name (solutionName) not defined in $solutionRoot/CDAF.solution, defaulting to current path, $solutionName"
fi

# Process Build and Package
$ciProcess "$solutionName" "$environmentBuild" "$buildNumber" "$revision" "$automationRoot"  "$workDirLocal" "$workDirRemote" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo "$scriptName : CI Failed! $ciProcess "$solutionName" "$environmentBuild" "$buildNumber" "$revision" "$automationRoot"  "$workDirLocal" "$workDirRemote" "$ACTION". Halt with exit code = $exitCode."
	exit $exitCode
fi

# Do not process Remote and Local Tasks if the action is just clean
if [ -z "$ACTION" ]; then
	$cdProcess "$solutionName" "$environmentDelivery" "$buildNumber" "$revision" "$automationRoot"  "$workDirLocal" "$workDirRemote" "$ACTION"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$scriptName : CD Failed! $cdProcess "$solutionName" "$environmentBuild" "$buildNumber" "$revision" "$automationRoot"  "$workDirLocal" "$workDirRemote" "$ACTION". Halt with exit code = $exitCode."
		exit $exitCode
	fi
fi
echo
echo "$scriptName : ------------------"
echo "$scriptName : Emulation Complete"
echo "$scriptName : ------------------"
echo