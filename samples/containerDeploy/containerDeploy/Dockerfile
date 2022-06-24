# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Copy all scripts (rely on StoreForLocal to limit this to only scripts required)
COPY *.sh ./

# Provision Build Dependancies
RUN ./bootstrapAgent.sh

# Import CDAF package into immutable machine
COPY properties/* /solution/deploy/
WORKDIR /solution/deploy
ADD deploy.tar.gz .

# Unlike containerBuild the workspace is not volume mounted, this replicates what the remote deploy process does leaving the image ready to run
CMD ["./deploy.sh", "${ENVIRONMENT}"]
