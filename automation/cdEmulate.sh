#!/usr/bin/env bash
# Emulate calling the package and deploy process as it would be from the automation toolset, 
# e.g. Bamboo or Jenkings, replacing buildNumber with timestamp
# workspace with temp space. The variables provided in Jenkins are emulated in the scripts
# themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

# Check Action
ACTION="$1"

scriptName=${0##*/}
source /etc/bash.bashrc

echo
echo "$scriptName : --------------------"
echo "$scriptName : Initialise Emulation"
echo "$scriptName : --------------------"
echo "$scriptName :   ACTION              : $ACTION"

workDirLocal="TasksLocal"
workDirRemote="TasksRemote"

# Framework structure
# Look for automation root definition, if not found, default
for i in $(ls -d */); do
	directoryName=${i%%/}
	if [ -f "$directoryName/CDAF.linux" ]; then
		automationRoot="$directoryName"
		echo "$scriptName :   automationRoot      : $automationRoot (CDAF.linux found)"
	fi
done
if [ -z "$automationRoot" ]; then
	automationRoot="automation"
	echo "$scriptName :   automationRoot      : $automationRoot (CDAF.linux not found)"
fi

# Build and Delivery Properties Lookup values
if [ ! $environmentBuild] ; then
	environmentBuild="BUILD"
fi
echo "$scriptName :   environmentBuild    : $environmentBuild"

if [ ! $environmentDelivery ]; then
	environmentDelivery="LINUX"
fi
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
if [ -f "$solutionRoot/ciProcess.sh" ]; then
	cdProcess="$solutionRoot/ciProcess.sh"
	echo "$ciProcess (override)"
else
	ciProcess="$automationRoot/processor/ciProcess.sh"
	echo "$ciProcess (default)"
fi

# Check for customised Delivery process
printf "$scriptName :   cdProcess           : "
if [ -f "$solutionRoot/deliverProcess.sh" ]; then
	cdProcess="$solutionRoot/deliverProcess.sh"
	echo "$cdProcess (override)"
else
	cdProcess="$automationRoot/processor/deliverProcess.sh"
	echo "$cdProcess (default)"
fi
# Packaging will ensure either the override or default delivery process is in the workspace root
cdInstruction="deliverProcess.sh"

# If a solution properties file exists, load the properties
if [ -f "$solutionRoot/CDAF.solution" ]; then
	echo
	echo "$scriptName : Load Solution Properties $solutionRoot/CDAF.solution"
	propertiesList=$($automationRoot/remote/transform.sh "$solutionRoot/CDAF.solution")
	echo "$propertiesList"
	eval $propertiesList
fi

# CDM-70 : If the Solution is not defined in the CDAF.solution file, use current working directory
# In Jenkins parameter is JOB_NAME 
if [ -z "$solutionName" ]; then
	solutionName=$(basename $(pwd))
	echo
	echo "$scriptName : solutionName not defined in $solutionRoot/CDAF.solution, defaulting to current root, $solutionName"
else
	echo
	echo "$scriptName : solutionName defined in $solutionRoot/CDAF.solution, using solution name $solutionName"	
fi

if [ -z "$ACTION" ]; then
	echo
	echo "$scriptName : ---------- CI Toolset Configuration Guide -------------"
	echo
    echo 'For TeamCity ...'
    echo "  Command Executable : $ciProcess"
    echo "  Command parameters : $solutionName $environmentBuild %build.number% %build.vcs.number% $automationRoot $workDirLocal $workDirRemote"
	echo
    echo 'For Go (requires explicit bash invoke) ...'
    echo '  Command   : /bin/bash'
    echo "  Arguments : -c '$ciProcess $solutionName $environmentBuild \${GO_PIPELINE_COUNTER} \${GO_REVISION} $automationRoot $workDirLocal $workDirRemote'"
    echo
    echo 'For Bamboo ...'
    echo "  Script file : $ciProcess"
	echo "  Argument    : $solutionName $environmentBuild \${bamboo.buildNumber} \${bamboo.repository.revision.number} $automationRoot $workDirLocal $workDirRemote"
    echo
    echo 'For Jenkins ...'
    echo "  Command : ./$ciProcess $solutionName $environmentBuild \$BUILD_NUMBER \$SVN_REVISION $automationRoot $workDirLocal $workDirRemote"
    echo
    echo 'For Team Foundation Server/Visual Studio Team Services'
	echo '  Set the build name to the solution, to assure known workspace name in Release phase.'
    echo '  Use the visual studio template and delete the nuget and VS tasks.'
	echo '  NOTE: The BUILD DEFINITION NAME must not contain spaces in the name as it is the directory'
	echo '        Set the build number $(rev:r) to ensure build number is an integer'
	echo '        Cannot use %BUILD_SOURCEVERSION% with external Git'
    echo "  Command Filename  : $solutionName/$ciProcess"
    echo "  Command arguments : $solutionName $environmentBuild \$BUILD_BUILDNUMBER \$BUILD_SOURCEVERSION $automationRoot $workDirLocal $workDirRemote"
    echo "  Working Directory : $solutionName"
    echo
	echo "$scriptName : -------------------------------------------------------"
fi
$ciProcess "$solutionName" "$environmentBuild" "$buildNumber" "$revision" "$automationRoot"  "$workDirLocal" "$workDirRemote" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo "$scriptName : CI Failed! $ciProcess "$solutionName" "$environmentBuild" "$buildNumber" "$revision" "$automationRoot"  "$workDirLocal" "$workDirRemote" "$ACTION". Halt with exit code = $exitCode."
	exit $exitCode
fi

# Do not process Remote and Local Tasks if the action is just clean
if [ -z "$ACTION" ]; then
	echo
	echo "$scriptName : ---------- Artefact Configuration Guide -------------"
	echo
	echo 'Configure artefact retention patterns to retain package and local tasks'
	echo
    echo 'For Bamboo ...'
    echo '  Name    : Package'
	echo '  Pattern : *.gz'
	echo
    echo '  Name    : TasksLocal'
	echo '  Pattern : TasksLocal/**'
	echo
    echo 'For VSTS / TFS 2015 ...'
    echo '  Use the combination of Copy files and Retain Artefacts from Visual Studio Solution Template'
    echo "  Source Folder   : \$(Agent.BuildDirectory)/s/$solutionName"
    echo '  Copy files task : TasksLocal/**'
    echo '                    *.gz'
	echo
	echo "$scriptName : -------------------------------------------------------"
	echo
	echo "$scriptName : ---------- CD Toolset Configuration Guide -------------"
	echo
	echo 'Note: artifact retention typically does include file attribute for executable, so'
	echo '  set the first step of deploy process to make all scripts executable'
	echo '  chmod +x ./*/*.sh'
	echo
	echo 'For TeamCity ...'
	echo "  Command Executable : $workDirLocal/$cdInstruction"
	echo "  Command parameters : $solutionName $environmentDelivery %build.number% $revision $automationRoot $workDirLocal $workDirRemote"
	echo
	echo 'For Go ...'
	echo '  requires explicit bash invoke'
	echo '  Command   : /bin/bash'
	echo "  Arguments : -c '$workDirLocal/$cdInstruction $solutionName \${GO_ENVIRONMENT_NAME} \${GO_PIPELINE_COUNTER} $revision $automationRoot $workDirLocal $workDirRemote'"
	echo
	echo 'For Bamboo ...'
	echo '  Warning! set Deployment project name to solution name, with no spaces'
	echo "  Script file : $workDirLocal/$cdInstruction"
	echo "  Argument    : $solutionName \${bamboo.deploy.environment} \${bamboo.buildNumber} \${bamboo.deploy.release} $automationRoot $workDirLocal $workDirRemote"
	echo
	echo "  note: set the release tag to (assuming no releases performed, otherwise, use the release number already set)"
	echo '  build-${bamboo.buildNumber} deploy-1'
	echo
	echo 'For Jenkins ...'
	echo '  Following is for use with delivery-pipeline-plugin, which does not provide'
	echo '  the upstream build number, so retrieve the BUILDNUMBER from the manifest.'
	echo '  # Load the $BUILDNUMBER from the manifest'
	echo '  propertiesList=$(TasksLocal/transform.sh TasksLocal/manifest.txt)'
	echo '  printf "$propertiesList"'
	echo '  eval $propertiesList'
	echo "  Command : ./$workDirLocal/$cdInstruction $solutionName $environmentDelivery \$BUILDNUMBER $revision $automationRoot $workDirLocal $workDirRemote"
	echo
	echo 'For Team Foundation Server/Visual Studio Team Services'
	echo '  Check the default queue for Environment definition.'
	echo '  Run an empty release initially to load the workspace, which can then be navigated to for following configuration.'
	echo "  Command Filename  : \$(System.DefaultWorkingDirectory)/$solutionName/drop/$workDirLocal/$cdInstruction"
	echo "  Command arguments : $solutionName \$RELEASE_ENVIRONMENTNAME \$BUILD_BUILDNUMBER \$RELEASE_RELEASENAME $automationRoot $workDirLocal $workDirRemote"
	echo "  Working folder    : \$(System.DefaultWorkingDirectory)/$solutionName/drop"
	echo
	echo "$scriptName : -------------------------------------------------------"

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
