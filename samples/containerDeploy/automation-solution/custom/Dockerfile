# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

MAINTAINER Jules Clements

ARG proxy
ENV http_proxy=$proxy

# Copy solution, provision and then build
WORKDIR solution

# Copy all scripts (rely on StoreForLocal to limit this to only scripts required)
COPY automation automation
COPY automation-solution/bootstrapAgent.sh automation-solution/bootstrapAgent.sh

# Provision Build Dependancies
RUN automation-solution/bootstrapAgent.sh

# Move to subdirectory for build, i.e. /solution/workspace, requires empty directory for volume mount
WORKDIR workspace

CMD ["./delivery.sh", "$DEPLOY_TARGET", "release", "deploy", "."]

