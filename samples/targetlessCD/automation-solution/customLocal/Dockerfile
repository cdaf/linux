# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

WORKDIR /solution

COPY pyserver.py .

CMD ["python", "pyserver.py"]
