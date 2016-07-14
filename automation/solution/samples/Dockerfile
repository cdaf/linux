FROM microsoft/dotnet

MAINTAINER Jules Clements

LABEL net.webhop.hdc.feature.version="@version@"

# Seed the runtime
RUN mkdir /opt/@project@ && cd /opt/@project@ && dotnet new 

# Copy the application code
COPY source/ /opt/@project@

# List the dependency manifest and Compile
RUN cat /opt/@project@/project.json && dotnet restore && dotnet build

# Default Port for Microsoft Templates
EXPOSE 5000

WORKDIR /opt/@project@
CMD ["dotnet", "run"]
