# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Only copy the scripts required
COPY automation automation
COPY automation-solution/bootstrapAgent.sh .
RUN ./bootstrapAgent.sh

# Prepare for non-root build
ARG userName
ARG userID
RUN adduser $userName --uid $userID --disabled-password --gecos ""
# RUN adduser $userName --uid $userID # CentOS
RUN chown $userName:$userName -R /solution
USER $userName

# Move to subdirectory for build, i.e. /solution/workspace
WORKDIR /solution/workspace

CMD echo 'Usage: docker run --tty --volume ${workspace}:/solution/workspace ${buildImage}:${newTag} ./automation/ci.sh $buildNumber'
