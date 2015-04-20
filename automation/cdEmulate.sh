#!/bin/bash
# Emulate calling the package and deploy process as it would be from the automation toolset, 
# e.g. Bamboo or Jenkings, replacing BUILD with timestamp
# workspace with temp space. The variables provided in Jenkins are emulated in the scripts
# themselves, that way the scripts remain portable, i.e. can be used in other CI tools.

# Check Action
ACTION="$1"

# If the environment is not set, default to DEV (template contains a DEV definition that uses localhost
if [ -z "$CD_ENV" ]; then
	ENVIRONMENT="DEV"
else
	ENVIRONMENT="$CD_ENV"
fi

# Automation Toolset Values

# Use the working directory for the package name
# In Jenkins parameter is JOB_NAME 
# In Bamboo parameter is  ${bamboo.buildNumber}
SOLUTION=$(basename $(pwd))

# Use timestamp in place of Jenkins BUILD_ID
BUILD=$(date "+%Y%m%d_%T")

# Use static string in place of Source Control revision, 
# In jenkins the parameter is REVISION
# In Bamboo the parameter is ${bamboo.repository.revision.number}
REVISION="55"

# User Defined Values
automationRoot="automation"
LOCAL_WORK_DIR="TasksLocal"
REMOTE_WORK_DIR="TasksRemote"

echo
echo "$0 : +-------------------------------------+"
echo "$0 : | Start Continuous Delivery emulation |"
echo "$0 : |         CDAF Version : 0.7.4        |"
echo "$0 : +-------------------------------------+"
echo
echo "$0 :   ACTION      : $ACTION"
echo "$0 :   ENVIRONMENT : $ENVIRONMENT"
echo
if [ -z "$ACTION" ]; then
    echo $0 : For TeamCity ...
    echo Command Executable : $automationRoot/buildandpackage/buildProjects.sh 
    echo Command parameters : $SOLUTION %build.number% %build.vcs.number% BUILD
    echo
    echo $0 : For Bamboo ...
    echo Script file : $automationRoot/buildandpackage/buildProjects.sh
	echo Argument : $SOLUTION \${bamboo.buildNumber} \${bamboo.repository.revision.number} BUILD
    echo
    echo $0 : For Jenkins ...
    echo Command : $automationRoot/buildandpackage/buildProjects.sh $SOLUTION %BUILD_NUMBER% %SVN_REVISION% BUILD
    echo
fi

./$automationRoot/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILD" "$REVISION" "$ENVIRONMENT" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo "$0 : Project Build Failed! ./$automationRoot/buildandpackage/buildProjects.sh "$SOLUTION" "$BUILD" "$REVISION" "$ENVIRONMENT" "$ACTION". Halt with exit code = $exitCode. "
	exit $exitCode
fi
echo
if [ -z "$ACTION" ]; then
    echo $0 : For TeamCity ...
    echo Command Executable : $automationRoot/buildandpackage/package.sh 
    echo Command parameters : $SOLUTION %build.number% %build.vcs.number% $LOCAL_WORK_DIR $REMOTE_WORK_DIR
    echo
    echo $0 : For Bamboo ...
    echo Script file : $automationRoot/buildandpackage/package.sh
	echo Argument : $SOLUTION \${bamboo.buildNumber} \${bamboo.repository.revision.number} $LOCAL_WORK_DIR $REMOTE_WORK_DIR
    echo
    echo $0 : For Jenkins ...
    echo Command : $automationRoot/buildandpackage/package.sh $SOLUTION %BUILD_NUMBER% %SVN_REVISION% $LOCAL_WORK_DIR $REMOTE_WORK_DIR
    echo
fi
    
./$automationRoot/buildandpackage/package.sh "$SOLUTION" "$BUILD" "$REVISION" "$LOCAL_WORK_DIR" "$REMOTE_WORK_DIR" "$ACTION"
exitCode=$?
if [ $exitCode -ne 0 ]; then
	echo "$0 : Package Failed! Halt with exit code = $exitCode."
	exit $exitCode
fi

# If not action is passed, proceed to deployment steps, any explicit action skips deploy
if [ -z "$ACTION" ]; then

	echo "$0 : +---------------------------------------------+"
	echo "$0 : |                                             |"
	echo "$0 : | This is where the toolset will retrieve the |"
	echo "$0 : | packaged artefefact and the local execution |"
	echo "$0 : | scripts in preparation for automated deploy |"
	echo "$0 : |                                             |"
	echo "$0 : +---------------------------------------------+"
	echo
	echo "$0 :   LOCAL_WORK_DIR = $LOCAL_WORK_DIR"
	echo
	echo $0 : For TeamCity ...
	echo Command Executable : /$LOCAL_WORK_DIR/remoteTasks.sh 
	echo Command parameters : $ENVIRONMENT %build.number% $SOLUTION $LOCAL_WORK_DIR
	echo
	echo $0 : For Bamboo ...
	echo Script file : \${bamboo.build.working.directory}/$LOCAL_WORK_DIR/remoteTasks.sh
	echo Argument : \${bamboo.deploy.environment} \${bamboo.buildNumber} \${bamboo.deploy.project} $LOCAL_WORK_DIR
	echo
	echo $0 : For Jenkins ...
	echo Command : /$LOCAL_WORK_DIR/remoteTasks.sh $ENVIRONMENT %BUILD_NUMBER% $SOLUTION $LOCAL_WORK_DIR
	echo
	./$LOCAL_WORK_DIR/remoteTasks.sh "$ENVIRONMENT" "$BUILD" "$SOLUTION" "$LOCAL_WORK_DIR"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Remote Deploy process failed! Returned $exitCode"
		exit $exitCode
	fi
	echo
	echo "$0 : +---------------------------------------------+"
	echo "$0 : |                                             |"
	echo "$0 : | Return to the build agent for post deploy   |"
	echo "$0 : |                                             |"
	echo "$0 : +---------------------------------------------+"
	echo
	echo $0 : For TeamCity ...
	echo Command Executable : /$LOCAL_WORK_DIR/localTasks.sh 
	echo Command parameters : $ENVIRONMENT %build.number% $SOLUTION $LOCAL_WORK_DIR
	echo
	echo $0 : For Bamboo ...
	echo Script file : \${bamboo.build.working.directory}/$LOCAL_WORK_DIR/localTasks.sh
	echo Argument : \${bamboo.deploy.environment} \${bamboo.buildNumber} \${bamboo.deploy.project} $LOCAL_WORK_DIR
	echo
	echo $0 : For Jenkins ...
	echo Command : /$LOCAL_WORK_DIR/localTasks.sh $ENVIRONMENT %BUILD_NUMBER% $SOLUTION $LOCAL_WORK_DIR
	echo
	./$LOCAL_WORK_DIR/localTasks.sh "$ENVIRONMENT" "$BUILD" "$SOLUTION" "$LOCAL_WORK_DIR"
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Remote Deploy process failed! Returned $exitCode"
		exit $exitCode
	fi

fi

echo
echo "$0 : +-----------------------------------+"
echo "$0 : | End Continuous Delivery emulation |"
echo "$0 : +-----------------------------------+"
echo