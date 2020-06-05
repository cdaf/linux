#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  
# Emulate calling the package and deploy process as it would be from the automation toolset, e.g. Bamboo or Jenkings. 
# Workspace with temp space. The variables provided in Jenkins are emulated in the scripts themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

# Check Action
ACTION="$1"

scriptName=${0##*/}

# Reload any environment variables
if [ -f "/etc/bash.bashrc" ]; then
	source /etc/bash.bashrc
fi
if [ -f "~/.bashrc" ]; then
	source ~/.bashrc
fi

echo; echo "$scriptName : --------------------"
echo "$scriptName : Initialise Emulation"
echo "$scriptName : --------------------"
echo "$scriptName :   ACTION         : $ACTION"
caseinsensitive=$(echo "$ACTION" | tr '[A-Z]' '[a-z]')

workDirLocal="TasksLocal"
workDirRemote="TasksRemote"

# Framework structure
automationRoot="$( cd "$(dirname "$0")" ; pwd -P )"
echo "$scriptName :   automationRoot : $automationRoot"
export CDAF_AUTOMATION_ROOT=$AUTOMATIONROOT

# Check for user defined solution folder, i.e. outside of automation root, if found override solution root
printf "$scriptName :   solutionRoot   : "
for directoryName in $(find . -maxdepth 1 -mindepth 1 -type d); do
	if [ -f "$directoryName/CDAF.solution" ] && [ "$directoryName" != "$LOCAL_WORK_DIR" ] && [ "$directoryName" != "$REMOTE_WORK_DIR" ]; then
		solutionRoot="$directoryName"
	fi
done
if [ -z "$solutionRoot" ]; then
	solutionRoot="$automationRoot/solution"
	echo "$solutionRoot (default, project directory containing CDAF.solution not found)"
else
	echo "$solutionRoot (override $solutionRoot/CDAF.solution found)"
fi

# If not set as an environment variablem, delivery properties Lookup values
if [ -z "${CDAF_DELIVERY}" ]; then
	if [ -f "$solutionRoot/deliveryEnv.sh" ]; then
		CDAF_DELIVERY=$($solutionRoot/deliveryEnv.sh)
		echo "$scriptName :   CDAF_DELIVERY  : $CDAF_DELIVERY (using override $solutionRoot/deliveryEnv.sh)"
	else
		if [ ! $CDAF_DELIVERY ]; then
			CDAF_DELIVERY="LINUX"
		fi
		echo "$scriptName :   CDAF_DELIVERY  : $CDAF_DELIVERY (override $solutionRoot/deliveryEnv.sh not found)"
	fi
fi

# Use a simple text file (${HOME}/buildnumber.counter) for incremental build number
if [ -f "${HOME}/buildnumber.counter" ]; then
	let "buildNumber=$(cat ${HOME}/buildnumber.counter)"
else
	let "buildNumber=0"
fi
if [ "$caseinsensitive" != "cdonly" ]; then
	let "buildNumber=$buildNumber + 1"
fi
echo $buildNumber > ${HOME}/buildnumber.counter

if [ -n "${CDAF_BRANCH_NAME}" ]; then
	revision=${CDAF_BRANCH_NAME}
else
	revision="release"
fi
echo "$scriptName :   buildNumber    : $buildNumber"
echo "$scriptName :   revision       : $revision"

# Check for customised CI process
printf "$scriptName :   ciProcess      : "
if [ -f "$solutionRoot/buildPackage.sh" ]; then
	cdProcess="$solutionRoot/buildPackage.sh"
	echo "$ciProcess (override)"
else
	ciProcess="$automationRoot/processor/buildPackage.sh"
	echo "$ciProcess (default)"
fi

# Check for customised Delivery process
printf "$scriptName :   cdProcess      : "
if [ -f "$solutionRoot/delivery.sh" ]; then
	cdProcess="$solutionRoot/delivery.sh"
	echo "$cdProcess (override)"
else
	cdProcess="$automationRoot/processor/delivery.sh"
	echo "$cdProcess (default)"
fi
# Packaging will ensure either the override or default delivery process is in the workspace root
cdInstruction="delivery.sh"

# If a solution properties file exists, load the properties
if [ -f "$solutionRoot/CDAF.solution" ]; then
	echo
	echo "$scriptName : Load Solution Properties $solutionRoot/CDAF.solution"
	propertiesList=$($automationRoot/remote/transform.sh "$solutionRoot/CDAF.solution")
	echo "$propertiesList"
	eval $propertiesList
fi

# If the Solution is not defined in the CDAF.solution file, do not attempt to derive, instead, throw error.
if [ -z "$solutionName" ]; then
	echo; echo "$scriptName : solutionName not defined in $solutionRoot/CDAF.solution, exiting with code 3"; exit 3
fi

if [ "$caseinsensitive" != "buildonly" ] && [ "$caseinsensitive" != "packageonly" ] && [ "$caseinsensitive" != "clean" ]; then
	echo
	echo "$scriptName : ---------- CI Toolset Configuration Guide -------------"
	echo
    echo 'For TeamCity ...'
    echo "  Command Executable : $ciProcess"
    echo "  Command parameters : %build.number% %build.vcs.number%"
	echo
    echo 'For Go (requires explicit bash invoke) ...'
    echo '  Command   : /bin/bash'
    echo "  Arguments : -c '$ciProcess \${GO_PIPELINE_COUNTER} \${GO_REVISION}'"
    echo
    echo 'For Bamboo ...'
    echo "  Script file : $ciProcess"
	echo "  Argument    : \${bamboo.buildNumber} \${bamboo.repository.branch.name}"
    echo
    echo 'For Jenkins ...'
    echo "  Command : $ciProcess \$BUILD_NUMBER \$JOB_NAME"
    echo
	echo 'Azure DevOps (formerly TFS/VSTS)'
	echo '  Set the build name to the solution, to assure known workspace name in Release phase.'
    echo '  Use the visual studio template and delete the nuget and VS tasks.'
    echo '  Instructions are based on default VS layout, i.e. repo, solution, projects, with the solution in the repo root.'
	echo '  NOTE: The BUILD DEFINITION NAME must not contain spaces in the name as it is the directory'
	echo '        Set the build number $(rev:r) to ensure build number is an integer'
	echo '        Cannot use %BUILD_SOURCEVERSION% with external Git'
    echo "  Command Filename  : $ciProcess"
    echo "  Command arguments : \$BUILD_BUILDNUMBER \$BUILD_SOURCEVERSION"
    echo '  Working directory : selected and set to blank (otherwise the path of the ciProcess will be used)'
	echo
    echo 'For GitLab (requires shell runner) ...'
    echo '  In .gitlab-ci.yml (in the root of the repository) add the following hook into the CI job'
    echo '    script: "automation/processor/buildPackage.sh ${CI_BUILD_ID} ${CI_BUILD_REF_NAME}"'
	echo
    echo 'For BlueMix ...'
    echo '  Similar to TFS/Azure DevOps, BlueMix supports a single "staging" directory for artefact retention'
    echo '  Build script : ./automation/processor/buildPackage.sh $BUILD_NUMBER $GIT_BRANCH staging@staging'
	echo
    echo 'For GitHub Actions ...'
    echo '  Copy the sample coded pipeline file from GitHub'
    echo '  https://github.com/cdaf/linux/tree/master/samples/github-actions'
    echo
	echo "$scriptName : -------------------------------------------------------"
fi
if [ "$caseinsensitive" != "cdonly" ]; then
	$ciProcess "$buildNumber" "$revision" "$ACTION"
	exitCode=$?
	if [ $exitCode -ne 0 ]; then
		echo "$scriptName : CI Failed! $ciProcess \"$buildNumber\" \"$revision\" \"$ACTION\". Halt with exit code = $exitCode."
		exit $exitCode
	fi
fi

# Do not process Remote and Local Tasks if the action is cionly or clean
if [ "$caseinsensitive" != "cionly" ] && [ "$caseinsensitive" != "buildonly" ] && [ "$caseinsensitive" != "packageonly" ] && [ "$caseinsensitive" != "clean" ]; then
	echo
	echo "$scriptName : ---------- Artefact Configuration Guide -------------"
	echo
	echo 'Configure artefact retention patterns to retain package and local tasks'
	echo
	echo 'For TeamCity ...'
    echo "  Artifact paths : TasksLocal => TasksLocal"
	echo "                 : *.gz"
	echo
	echo 'For Jenkins ...'
    echo '  Use Post-build Action Archive the Artefacts'
	echo "  Files to archive : TasksLocal/**, *.gz"
	echo
    echo 'For Go ...'
    echo '  Source        | Destination | Type'
	echo '  *.gz          | package     | Build Artifact'
    echo '  TasksLocal/** |             | Build Artifact'
	echo
    echo 'For Bamboo ...'
    echo '  Name    : Package'
	echo '  Pattern : *.gz'
	echo
    echo '  Name    : TasksLocal'
	echo '  Pattern : TasksLocal/**'
	echo
    echo 'For Azure DevOps (formerly TFS/VSTS)'
    echo '  Use the combination of Copy files and Retain Artefacts from Visual Studio Solution Template'
    echo "  Source Folder   : \$(Agent.BuildDirectory)/s/"
    echo '  Copy files task : TasksLocal/**'
    echo '                    *.gz'
	echo
    echo 'For GitLab (.gitlab-ci.yml, within the build job definition) ...'
    echo '    artifacts:'
    echo '      paths:'
    echo '      - TasksLocal/'
    echo '      - .gz'
	echo
	echo 'For BlueMix ...'
	echo '  Use the staging directory created based on staging@ argument'
	echo '  Build archive directory : staging'
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
	echo '  Choose "Deployment" build'
	echo '  "Use Finish Build" trigger (branch filter +:<default>)'
	echo '  Configure artifact dependency using "Build from the same chain"'
	echo '  Add a Configuration parameter from build.vcs.number to %env.BUILD_NUMBER%'
	echo '  Add Command Line build step'
	echo "  Command Executable : $workDirLocal/$cdInstruction \$TEAMCITY_BUILDCONF_NAME \$build.number"
	echo
	echo 'For Go ...'
	echo '  requires explicit bash invoke'
	echo '  Command   : /bin/bash'
	echo "  Arguments : -c '$workDirLocal/$cdInstruction \${GO_ENVIRONMENT_NAME}'"
	echo
	echo 'For Bamboo ...'
	echo '  Warning! Ensure there are no spaces in the environment name or release (by default release Release-xx)'
	echo "  Script file : $workDirLocal/$cdInstruction"
	echo "  Argument    : \${bamboo.deploy.environment} \${bamboo.deploy.release}"
	echo
	echo 'For Jenkins ...'
	echo '  Artefacts do not retain their executable bit:'
	echo '	chmod +x ./*/*.sh'
	echo '  Promote plugin:'
	echo '    For each environment, the environment name is a literal which needs to be defined each time'
	echo "    Command : ./$workDirLocal/$cdInstruction <environment name> \$PROMOTED_NUMBER"
	echo '  Delivery Pipeline plugin:'
	echo '    Retrieve the upstream build number from the manifest. Can use the Job Name as Environment Name'
	echo '    Command : ./TasksLocal/transform.sh ./TasksLocal/manifest.txt'
	echo '    Command : eval $(./TasksLocal/transform.sh ./TasksLocal/manifest.txt)'
	echo '    Command : ./TasksLocal/delivery.sh $JOB_NAME $BUILDNUMBER'
	echo
	echo 'For Azure DevOps (formerly TFS/VSTS)'
	echo '  Verify the queue for each Environment definition, and ensure Environment names do not contain spaces.'
	echo '  Create an "Empty" Release definition, and use the "Command Line" utility task (note, requires double quote when more than one argument).'
	echo '    Tool           : Run'
	echo '    Script         : chmod +x **/*.sh && ./TasksLocal/delivery.sh $RELEASE_ENVIRONMENTNAME $RELEASE_RELEASENAME'
	echo "    Working folder : \$(System.DefaultWorkingDirectory)/$solutionName/drop"
	echo
	echo '  then add "Shell Script" utility task to execute the delivery process'
	echo "    Command Filename  : \$(System.DefaultWorkingDirectory)/$solutionName/drop/$workDirLocal/$cdInstruction"
	echo '    Command arguments : $RELEASE_ENVIRONMENTNAME $RELEASE_RELEASENAME'
	echo "    Working folder    : \$(System.DefaultWorkingDirectory)/$solutionName/drop"
	echo
    echo 'For GitLab (requires shell runner) ...'
    echo '  If using the sample .gitlab-ci.yml simply clone and change the Environment literal'
    echo '  variables:'
    echo '    ENV: "<environment>"'
    echo "    script: \"$workDirLocal/$cdInstruction \${ENV} \${CI_PIPELINE_ID}\""
    echo '    environment: <environment>'
	echo
	echo 'For BlueMix ...'
	echo '  Ensure staging@ directive has been used in build or the relative path will be incorrect'
	echo '    ./TasksLocal/delivery.sh $IDS_STAGE_NAME $IDS_JOB_NAME'
   	echo
	echo "$scriptName : -------------------------------------------------------"

	if [ "$caseinsensitive" != "cionly" ]; then
		$cdProcess "$CDAF_DELIVERY"
		exitCode=$?
		if [ $exitCode -ne 0 ]; then
			echo "$scriptName : CD Failed! $cdProcess \"$CDAF_DELIVERY\". Halt with exit code = $exitCode."
			exit $exitCode
		fi
	fi
fi

echo
echo "$scriptName : ------------------"
echo "$scriptName : Emulation Complete"
echo "$scriptName : ------------------"
echo
