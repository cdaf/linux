# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

MAINTAINER Jules Clements

ARG proxy
ENV http_proxy=$proxy

# Copy solution, provision and then build
WORKDIR solution

# Provision and restore dependancies
COPY automation automation
RUN ./automation/provisioning/base.sh curl

# Same provisioning used in Vagrantfile
COPY bootstrapTarget.sh .
RUN ./bootstrapTarget.sh

# Move to subdirectory for mount, i.e. /solution/workspace
WORKDIR workspace

ENV MULE_ENV dev
ENV secret.key=

CMD ["./runner.sh", "arg1"]
