# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

ARG HTTP_PROXY
ENV HTTP_PROXY=$HTTP_PROXY

# Copy solution, provision and then build
WORKDIR /solution

# Copy all scripts (rely on StoreForLocal to limit this to only scripts required)
COPY automation automation
COPY bootstrapTest.sh .
RUN chmod +x bootstrapTest.sh
RUN ./bootstrapTest.sh

# Place entry script
COPY executeTest.sh .

# Move to (empty) subdirectory for mount
WORKDIR /solution/workspace

CMD ["../executeTest.sh", "AUTO_TEST"]
