# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

WORKDIR /home/root

COPY provision.sh .
RUN ./provision.sh

CMD ["sleep", "infinity"]
