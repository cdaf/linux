# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Copy all scripts (rely on StoreForLocal to limit this to only scripts required)
COPY automation automation

# Provision Build Dependancies
RUN automation/provisioning/base.sh 'openjdk-8-jdk-headless curl'
RUN curl -LO https://github.com/rundeck/rundeck-cli/releases/download/v1.3.4/rd-1.3.4.zip
RUN jar -xvf rd-1.3.4.zip
RUN mv rd-1.3.4 /opt
RUN chmod +x /opt/rd-1.3.4/bin/rd
ENV PATH=/opt/rd-1.3.4/bin:$PATH

COPY properties/* /solution/deploy/
WORKDIR /solution/deploy
ADD deploy.tar.gz .

# Unlike containerBuild the workspace is not volume mounted, this replicates what the remote deploy process does leaving the image ready to run
WORKDIR /solution/deploy
CMD ["java", "-version"]
