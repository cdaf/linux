# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

ARG proxy
ENV http_proxy=$proxy

# Copy solution, provision and then build
WORKDIR /solution

# Copy all scripts (rely on StoreForLocal to limit this to only scripts required)
COPY automation automation
COPY bootstrapTarget.sh .
RUN chmod +x bootstrapTarget.sh
RUN ./bootstrapTarget.sh

# Place entry script
COPY keepAlive.sh .

# Move to (empty) subdirectory for mount
WORKDIR /solution/workspace

CMD ["../keepAlive.sh", "SERVER"]
