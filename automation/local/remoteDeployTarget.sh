#!/usr/bin/env bash
set -e

# This script provides a repeatable deployment process. This uses two arguments, the target environment
# identifier and the $3 to deploy. Note: each $3 produced is expected to be uniquely identifiable.

if [ -z "$1" ]; then
	echo "$0 Environment Argument not passed. HALT!"
	exit 1
else
	ENVIRONMENT=$1
fi

if [ -z "$2" ]; then
	echo "$0 Build Argument not passed. HALT!"
	exit 2
else
	BUILDNUMBER=$2
fi

if [ -z "$3" ]; then
	echo "$0 : Solution Name not supplied. HALT!"
	exit 3
else
	SOLUTION=$3
fi

if [ -z "$4" ]; then
	echo "$0 : Deploy Target symbol not supplied. HALT!"
	exit 4
else
	DEPLOY_TARGET=$4
fi

if [ -z "$5" ]; then
	echo "$0 : Default working directory not supplied. HALT!"
	exit 5
else
	WORK_DIR_DEFAULT=$5
fi

OPT_ARG=$6

encryptedFileDir="./$WORK_DIR_DEFAULT/cryptRemote"

echo "$0 : --- Preparing $DEPLOY_TARGET ---"
deployHost=$(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/$DEPLOY_TARGET" "deployHost")
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Read of deployHost from ./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/$DEPLOY_TARGET failed! Returned $exitCode"
	exit $exitCode
else
	echo "$0 :   deployHost : $deployHost"
fi

deployUser=$(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/$DEPLOY_TARGET" "deployUser")
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Read of deployUser from ./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/$DEPLOY_TARGET failed! Returned $exitCode"
	exit $exitCode
else
	echo "$0 :   deployUser : $deployUser"
fi

deployLand=$(./$WORK_DIR_DEFAULT/getProperty.sh "./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/$DEPLOY_TARGET" "deployLand")
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Read of deployLand from ./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/$DEPLOY_TARGET failed! Returned $exitCode"
	exit $exitCode
else
	echo "$0 :   deployLand : $deployLand"
fi

if [[ $deployHost == *'$'* ]]; then
	deployHost=$(eval echo $deployHost)
	echo "$0 :   deployHost : $deployHost (evaluated)"
fi
if [[ $deployUser == *'$'* ]]; then
	deployUser=$(eval echo $deployUser)
	echo "$0 :   deployUser : $deployUser (evaluated)"
fi
if [[ $deployLand == *'$'* ]]; then
	deployLand=$(eval echo $deployLand)
	echo "$0 :   deployLand : $deployLand (evaluated)"
fi

# Process the deployHost, stripping out the port if passed, i.e. localhost:2222
sep=':'
case $deployHost in
	(*"$sep"*)
    	    deployPort=${deployHost#*"$sep"}
			deployHost=${deployHost%%"$sep"*}
    	    ;;
		(*)
    	    userHost=$deployHost
    	    deployPort="22"
    ;;
esac

echo
# Check if build has already been deployed on this target ..."
ssh -p $deployPort -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $deployUser@$deployHost 'bash -s' < ./$WORK_DIR_DEFAULT/remotePackageManagement.sh "$deployLand" "$SOLUTION-$BUILDNUMBER"
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : ssh $deployUser@$deployHost 'bash -s' < ./$WORK_DIR_DEFAULT/remotePackageManagement.sh $deployLand $SOLUTION-$BUILDNUMBER failed! Returned $exitCode"
	exit $exitCode
fi

echo
echo "$0 : Copy package ($SOLUTION-$BUILDNUMBER.tar.gz) to target host ($deployHost)"
scp -P $deployPort -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./$SOLUTION-$BUILDNUMBER.tar.gz $deployUser@$deployHost:$deployLand/
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Copy package ($SOLUTION-$BUILDNUMBER.tar.gz) to target host ($deployUser@$deployHost:$deployLand) failed! Returned $exitCode"
	exit $exitCode
fi

echo
echo "$0 : Extract the contents of the Package on the remote host ($deployHost)"
ssh -p $deployPort -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $deployUser@$deployHost 'cat | bash /dev/stdin ' "$SOLUTION-$BUILDNUMBER $deployLand" < ./$WORK_DIR_DEFAULT/extract.sh
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Extract the contents of the Package on the remote host ($SOLUTION-$BUILDNUMBER/$deployLand) failed! Returned $exitCode"
	exit $exitCode
fi

echo
echo "$0 : Copy the Properties file (./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/$DEPLOY_TARGET) to the extracted directory"
scp -P $deployPort -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./$WORK_DIR_DEFAULT/propertiesForRemoteTasks/$DEPLOY_TARGET $deployUser@$deployHost:$deployLand/$SOLUTION-$BUILDNUMBER
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : Copy the Properties file ($deployLand/$SOLUTION-$BUILDNUMBER/$DEPLOY_TARGET) to the extracted directory failed! Returned $exitCode"
	exit $exitCode
fi


if [ -d  "$encryptedFileDir" ]; then
	echo
	echo "$0 : Copy the encrypted password files from $encryptedFileDir ..."
	./$WORK_DIR_DEFAULT/sendCrypt.sh $ENVIRONMENT $BUILDNUMBER $SOLUTION $deployUser $deployHost $deployLand $encryptedFileDir
	exitCode=$?
	if [ "$exitCode" != "0" ]; then
		echo "$0 : ./$WORK_DIR_DEFAULT/sendCrypt.sh $ENVIRONMENT $BUILDNUMBER $SOLUTION $deployUser $deployHost $deployLand $encryptedFileDir failed! Returned $exitCode"
		exit $exitCode
	fi
fi

echo
echo "$0 : --- Transferring control to $deployUser@$deployHost for $DEPLOY_TARGET ---"
ssh -p $deployPort -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $deployUser@$deployHost $deployLand/$SOLUTION-$BUILDNUMBER/deploy.sh "$DEPLOY_TARGET" "$deployLand/$SOLUTION-$BUILDNUMBER" "$OPT_ARG" < /dev/null
exitCode=$?
if [ "$exitCode" != "0" ]; then
	echo "$0 : ssh $deployUser@$deployHost $deployLand/$SOLUTION-$BUILDNUMBER/deploy.sh $DEPLOY_TARGET $deployLand/$SOLUTION-$BUILDNUMBER $OPT_ARG failed! Returned $exitCode"
	exit $exitCode
fi
