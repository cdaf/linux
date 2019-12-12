# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

MAINTAINER Jules Clements

ARG proxy
ENV http_proxy=$proxy

# Copy solution, provision and then build
WORKDIR solution

# Only copy the scripts required
COPY automation/provisioning/base.sh automation/provisioning/base.sh
COPY automation/provisioning/installApacheMaven.sh automation/provisioning/installApacheMaven.sh
COPY automation-solution/bootstrapAgent.sh automation-solution/bootstrapAgent.sh

# Provision Build Dependancies
RUN automation-solution/bootstrapAgent.sh

# Prepare for non-root build
ARG userName
ARG userID
RUN adduser $userName --uid $userID --disabled-password --gecos ""
# RUN adduser $userName --uid $userID # CentOS
RUN chown $userName:$userName -R /solution
USER $userName

# Move to subdirectory for build, i.e. /solution/workspace
WORKDIR workspace

CMD echo 'Usage: docker run --tty --volume ${workspace}:/solution/workspace ${buildImage}:${newTag} ./automation/processor/buildPackage.sh $buildNumber'
