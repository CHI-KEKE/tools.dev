#/usr/bin/env bash

# -----------------------------------------------------------------------------
# Flags to Control Build Flow
# -----------------------------------------------------------------------------

NYP_SETTING__RAW_PACK_IMAGE="true"
NYP_SETTING__RAW_PUSH_IMAGE="true"

NYP_SETTING__DOCKER_BUILD_IMAGE="true"
NYP_SETTING__DOCKER_PUSH_IMAGE="true"

NYP_SETTING__DOTNET_BUILD_NUGET="false"
NYP_SETTING__DOTNET_PACK_NUGET="false"
NYP_SETTING__DOTNET_PUSH_NUGET="false"

# -----------------------------------------------------------------------------
# DotNET info.
# -----------------------------------------------------------------------------
DOTNET_BUILD_BASE_IMAGE="docker.build.91app.io/91app/dotnet-sdk-base:10"
DOTNET_RUNTIME_BASE_IMAGE="mcr.microsoft.com/dotnet/aspnet:10.0"

NYS_BUILD_DOCKERFILE="Dockerfile"

NYS_ENVNAME_PREFIX="SAMPLE_PROJECT_"


