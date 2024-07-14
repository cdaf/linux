# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Apply custom provisioning steps here
RUN npm install -g anypoint-cli-v4 && \
  anypoint-cli-v4 plugins:install anypoint-cli-account-plugin && \
  anypoint-cli-v4 plugins:install anypoint-cli-exchange-plugin && \
  anypoint-cli-v4 plugins:install anypoint-cli-api-mgr-plugin && \
  anypoint-cli-v4 plugins:install anypoint-cli-cloudhub-plugin && \
  anypoint-cli-v4 plugins:install anypoint-cli-governance-plugin && \
  anypoint-cli-v4 plugins:install anypoint-cli-runtime-mgr-plugin && \
  anypoint-cli-v4 plugins:install anypoint-cli-datagraph-plugin && \
  anypoint-cli-v4 plugins:install anypoint-cli-designcenter-plugin

# Prepare for non-root deploy
ARG userName
ARG userID

RUN user=$(id -nu $userID 2>/dev/null || exit 0) ; \
if [ ! -z "$user" ]; then \
userdel -f $user ; \
fi ;  \
adduser $userName --uid $userID --disabled-password --gecos "" ; \
chown $userName -R /solution

# Import CDAF package into immutable machine
COPY properties/* /solution/deploy/
WORKDIR /solution/deploy
ADD deploy.tar.gz .

COPY release.sh /solution/deploy/

RUN chown $userName -R /solution/deploy
USER $userName

# Unlike containerBuild the workspace is not volume mounted, this replicates what the remote deploy process does leaving the image ready to run
CMD ["./deploy.sh", "${ENVIRONMENT}"]
