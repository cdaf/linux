# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

WORKDIR /app/publish
EXPOSE 80
EXPOSE 443

ADD content.tar.gz /usr/share/nginx/html/

# Normal containers run a console application, this example works in a more similar way to a traditional daemon server
# CMD ["dotnet", "app.dll"]
