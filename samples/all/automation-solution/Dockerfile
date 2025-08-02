# DOCKER-VERSION 1.2.0
FROM centos
MAINTAINER Jules Clements

# Copy solution, provision and then build
WORKDIR solution

# CDAF
COPY automation automation

# Provision and restore dependancies
COPY automation-solution/bootstrapAgent.sh automation-solution/bootstrapAgent.sh

# Provision Build Dependancies
RUN automation-solution/bootstrapAgent.sh

# Prepare for non-root build
RUN chmod 777 -R /solution
ARG userName
ARG userID
RUN useradd -m -k /dev/null -u $userID -s /usr/sbin/nologin -c "" $userName
USER $userName

# < Apply any user specific tasks here >

# Move to subdirectory for build, i.e. /solution/workspace
WORKDIR workspace

CMD echo 'Usage: docker run --tty --volume ${workspace}:/solution/workspace ${buildImage}:${newTag} ./automation/ci.sh $buildNumber'
