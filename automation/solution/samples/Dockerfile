# DOCKER-VERSION 1.2.0
FROM ubuntu
MAINTAINER Jules Clements

# Copy solution, provision and then build
WORKDIR solution

COPY automation automation
COPY automation-solution/bootstrapAgent.sh automation-solution/bootstrapAgent.sh

# Provision Build Dependancies
RUN automation-solution/bootstrapAgent.sh

# Build and Package Solution, use mapped volume so the resulting package is available on the local host, i.e.
# docker run -it -v /Users/me/mule:/workspace mule
CMD automation/remote/entrypoint.sh
