# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE=docker.io/cdaf/linux:latest
FROM ${CONTAINER_IMAGE}

# Perform any custom provisioning steps here
# If not using a CDAF base image
# RUN curl -s https://raw.githubusercontent.com/cdaf/linux/master/provisioning.sh | bash -s -- '/opt/provisioning'
RUN base curl

CMD ["sleep", "infinity"]
