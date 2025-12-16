# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE=docker.io/cdaf/linux:latest
FROM ${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Perform any custom provisioning steps here
# If not using a CDAF base image
# RUN curl -s https://raw.githubusercontent.com/cdaf/linux/master/provisioning.sh | bash -s -- '/opt/provisioning'
RUN base curl

# Prepare for non-root build
ARG userName
ARG userID
RUN useradd -m -k /dev/null -u $userID -s /usr/sbin/nologin -c "" $userName
RUN chown $userName:$userName -R /solution
USER $userName

# Move to subdirectory for build, i.e. /solution/workspace
WORKDIR /solution/workspace

CMD ["sleep", "infinity"]
