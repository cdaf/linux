#!/usr/bin/env bash
function executeExpression {
	echo "[$scriptName] $1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		echo "$0 : Exception! $1 returned $exitCode"
		exit $exitCode
	fi
}

scriptName='imageBuild.sh'

echo;echo "[$scriptName] --- start ---"
SOLUTION=$1
if [ -z "$SOLUTION" ]; then
	echo "[$scriptName] SOLUTION not supplied, exit with code 1."
	exit 1
else
	echo "[$scriptName] SOLUTION      : $SOLUTION"
fi

BUILDNUMBER=$2
if [ -z "$BUILDNUMBER" ]; then
	echo "[$scriptName] BUILDNUMBER not supplied, exit with code 2."
	exit 2
else
	echo "[$scriptName] BUILDNUMBER   : $BUILDNUMBER"
fi

REVISION=$3
if [ -z "$REVISION" ]; then
	echo "[$scriptName] REVISION      : (not supplied)"
else
	echo "[$scriptName] REVISION      : $REVISION"
fi

ACTION=$4
if [ -z "$ACTION" ]; then
	echo "[$scriptName] ACTION        : (not supplied)"
else
	echo "[$scriptName] ACTION        : $ACTION"
fi

echo "Load product (solution) attributes"

eval $(./automation/remote/transform.sh ./automation-solution/CDAF.solution)
productVersion+=".${BUILDNUMBER}"

publishedPort=8079
dockerExposedPort=8080
echo "productVersion  = ${productVersion}"
echo "publishedPort   = ${publishedPort}"

if [ -d "buildImage" ]; then
	executeExpression "rm -rf buildImage/**"
else
	executeExpression "mkdir buildImage"
fi
executeExpression "cp automation-solution/Dockerfile buildImage"
executeExpression "cp springboot/target/*.jar buildImage"
executeExpression "cd buildImage"

echo "Build the container, will create image ${SOLUTION} tagged with $BUILDNUMBER"

executeExpression "../automation/remote/dockerBuild.sh ${SOLUTION} $BUILDNUMBER ${productVersion}"

echo "Create an instance for smoke test, dockerRun.sh ${SOLUTION} ${dockerExposedPort} ${publishedPort} $BUILDNUMBER"

executeExpression "../automation/remote/dockerRun.sh ${SOLUTION} ${dockerExposedPort} ${publishedPort} $BUILDNUMBER"

echo "Wait for application to start"

executeExpression "../automation/remote/dockerLog.sh ${SOLUTION}_${publishedPort} 'Started SpringbootApplication in' 300"

echo "Verify href returned from configured context http://localhost:${publishedPort}/spring/profile"

verify=$(curl -s http://localhost:${publishedPort}/spring/profile | grep href)

if [ -n "$verify" ]; then
	echo "href confirmed"
else
	echo "href not found!"
	exit 70
fi

echo "Stop and remove the build test container (does not affect the image)"
echo "Remove process based on environment, not instances. Remove ${SOLUTION}.${BUILDNUMBER}"
executeExpression "../automation/remote/dockerRemove.sh ${SOLUTION} $BUILDNUMBER"

executeExpression "cd .."

echo "Only push the tested image to the registry if processing master"
if [[ $REVISION == 'master' ]]; then
	executeExpression "docker tag ${SOLUTION}:$BUILDNUMBER localhost/${SOLUTION}:$BUILDNUMBER"
	executeExpression "docker push localhost/${SOLUTION}:$BUILDNUMBER"
fi

echo; echo "[$scriptName] --- end ---"; echo
