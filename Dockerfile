# Multi-stage Dockerfile for Mizan ASP.NET Core Web API on Google Cloud Run
ARG DOTNET_VERSION=10.0

# 1. Runtime Base
FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_VERSION} AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 10000
ENV ASPNETCORE_ENVIRONMENT=Production

# Install Kerberos GSSAPI library for Npgsql/PostgreSQL and SSL certs
USER root
RUN apt-get update && apt-get install -y --no-install-recommends libgssapi-krb5-2 ca-certificates && rm -rf /var/lib/apt/lists/*
USER $APP_UID

# 2. Build Stage
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION} AS build
WORKDIR /src

# Copy csproj files for optimal layer caching
COPY ["src/Mizan.Domain/Mizan.Domain.csproj", "src/Mizan.Domain/"]
COPY ["src/Mizan.Contracts/Mizan.Contracts.csproj", "src/Mizan.Contracts/"]
COPY ["src/Mizan.Application/Mizan.Application.csproj", "src/Mizan.Application/"]
COPY ["src/Mizan.Infrastructure/Mizan.Infrastructure.csproj", "src/Mizan.Infrastructure/"]
COPY ["src/Mizan.Api/Mizan.Api.csproj", "src/Mizan.Api/"]

RUN dotnet restore "src/Mizan.Api/Mizan.Api.csproj"

# Copy source files
COPY src/ src/

WORKDIR "/src/src/Mizan.Api"
RUN dotnet build "Mizan.Api.csproj" -c Release -o /app/build

# 3. Publish Stage
FROM build AS publish
RUN dotnet publish "Mizan.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# 4. Production Final
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Use built-in non-root app user for enhanced container security
USER $APP_UID

ENTRYPOINT ["dotnet", "Mizan.Api.dll"]
