# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

WORKDIR /app/publish
EXPOSE 80
EXPOSE 443

ADD app.tar.gz .

ENTRYPOINT ["dotnet", "conn.dll"]
