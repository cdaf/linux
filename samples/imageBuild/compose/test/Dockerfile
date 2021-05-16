# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

# Wrapper script to keep container running after executing tests
WORKDIR /solution

# Alternative is to filter scripts in storeForLocal and just copy automation directory, see compose.tsk
COPY base.sh ./automation/provisioning/base.sh
COPY capabilities.sh ./automation/remote/capabilities.sh

COPY bootstrapTest.sh .
RUN chmod +x bootstrapTest.sh
RUN ./bootstrapTest.sh

# Place entry script
COPY executeTest.sh .

# Move to (empty) subdirectory for mount
WORKDIR /solution/workspace

CMD ["../executeTest.sh", "AUTO_TEST"]
