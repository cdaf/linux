# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE=docker.io/cdaf/linux:latest
FROM ${CONTAINER_IMAGE}

WORKDIR /solution
ENV LISTENING_PORT=8000

COPY pyserver.py .

CMD ["python", "-u", "pyserver.py"]
