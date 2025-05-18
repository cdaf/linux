# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

# Copy solution, provision and then build
WORKDIR /solution

# Place entry script
COPY executeTest.sh .

# Create external user in image
ARG userName
ARG userID
RUN adduser $userName --uid $userID --disabled-password --gecos ""
# RUN adduser $userName --uid $userID # CentOS
RUN chown $userName:$userName -R /solution
USER $userName

CMD ["./executeTest.sh", "target:8000"]
