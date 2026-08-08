# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE=docker.io/cdaf/linux:latest
FROM ${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Place entry script
COPY executeTest.sh .

# Create external user in image
ARG userName
ARG userID

RUN user=$(id -nu $userID 2>/dev/null || exit 0) ; \
	if [ ! -z "$user" ]; then \
		userdel -f $user ; \
	fi ;  \
	useradd -m -k /dev/null -u $userID -s /usr/sbin/nologin -c "" $userName ; \
	chown $userName -R /solution/workspace

RUN chown $userName:$userName -R /solution
USER $userName

CMD ["./executeTest.sh", "target:8000"]
