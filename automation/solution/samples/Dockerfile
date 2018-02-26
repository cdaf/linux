# DOCKER-VERSION 1.2.0
FROM ubuntu
MAINTAINER Jules Clements

# Copy solution, provision and then build
WORKDIR solution

COPY automation automation
COPY automation-solution/bootstrapAgent.sh automation-solution/bootstrapAgent.sh

# Provision Build Dependancies
RUN automation-solution/bootstrapAgent.sh

WORKDIR workspace

CMD echo 'Usage: docker run --tty --volume ${workspace}:/solution/workspace ${buildImage}:${newTag} ./automation/processor/buildPackage.sh $buildNumber'
