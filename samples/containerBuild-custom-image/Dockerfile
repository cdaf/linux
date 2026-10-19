# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE=docker.io/cdaf/linux:latest
FROM ${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Perform any custom provisioning steps here
# CDAF Provisioning scripts are no longer included in the base image
RUN curl -s https://raw.githubusercontent.com/cdaf/linux/master/provisioning.sh | bash -s -- '/opt/provisioning'

# cURL is included in the base image, but this included to verify provisioning scripts are installed
RUN base.sh curl

# Prepare for non-root build
WORKDIR /solution/workspace
ARG userName
ARG userID
RUN user=$(id -nu $userID 2>/dev/null || exit 0) ; \
if [ ! -z "$user" ]; then \
userdel -f $user ; \
fi ;  \
useradd -m -k /dev/null -u $userID -s /usr/sbin/nologin -c "" $userName

RUN chown $userName:$userName -R /solution/workspace
USER $userName

CMD ["sleep", "infinity"]
