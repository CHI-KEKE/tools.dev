# Provisioned by NYP, version: 0.4.0

# -----------------------------------------------------------------------------
# Base Image for Build and Runtime
# -----------------------------------------------------------------------------
ARG DOTNET_BUILD_BASE_IMAGE
ARG DOTNET_RUNTIME_BASE_IMAGE
ARG DOTNET_BUILD_CONFIG
ARG BUILD_ID
ARG NYS_FQDN
ARG NYS_PORT
ARG NYP_JOBNAME

# -----------------------------------------------------------------------------
# Container for Building
# -----------------------------------------------------------------------------
FROM ${DOTNET_BUILD_BASE_IMAGE} AS dotnet-build-env

ARG DOTNET_BUILD_CONFIG
ARG BUILD_ID
ARG NYS_FQDN
ARG NYS_PORT
ARG NYP_JOBNAME

WORKDIR /src
COPY ./src .

RUN dotnet restore
RUN dotnet publish -c ${DOTNET_BUILD_CONFIG} -o /out
#if(isFlatStruct)
COPY ./src/${NYS_FQDN}/.manifest /out/.manifest
#endif
#if(isModuleStruct)
COPY ./src/Web/${NYS_FQDN}/.manifest /out/.manifest
#endif
COPY ./workdir/${NYP_JOBNAME}/releng.json /out/.manifest/

# -----------------------------------------------------------------------------
# Container for Publishing Image
# -----------------------------------------------------------------------------
FROM ${DOTNET_RUNTIME_BASE_IMAGE}

ARG NYS_FQDN
ARG NYS_PORT

ENV NYS_FQDN=${NYS_FQDN}
ENV NYS_PORT=${NYS_PORT}

# Setting Timezone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

EXPOSE ${NYS_PORT}
WORKDIR /app
COPY --from=dotnet-build-env /out .

# Execute
CMD dotnet /app/${NYS_FQDN}.dll
