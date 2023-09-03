# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Prepare for non-root deploy
ARG userName
ARG userID

RUN user=$(id -nu $userID 2>/dev/null || exit 0) ; \
if [ ! -z "$user" ]; then \
userdel -f $user ; \
fi ;  \
adduser $userName --uid $userID --disabled-password --gecos "" ; \
chown $userName -R /solution
USER ${userName}

# Copy all scripts (rely on StoreForLocal to limit this to only scripts required)
COPY *.sh ./

# Provision Build Dependancies
RUN ./bootstrapAgent.sh

# Import CDAF package into immutable machine
COPY properties/* /solution/deploy/
WORKDIR /solution/deploy
ADD deploy.tar.gz .

COPY release.sh /solution/deploy/

# Unlike containerBuild the workspace is not volume mounted, this replicates what the remote deploy process does leaving the image ready to run
CMD ["./deploy.sh", "${ENVIRONMENT}"]
