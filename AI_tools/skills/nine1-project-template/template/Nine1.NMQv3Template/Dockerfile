# -----------------------------------------------------------------------------
# Base Image for Build and Runtime
# -----------------------------------------------------------------------------
ARG DOTNET_BUILD_BASE_IMAGE
ARG DOTNET_RUNTIME_BASE_IMAGE


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

WORKDIR /src/${NYS_FQDN}

RUN dotnet restore
RUN dotnet publish -c ${DOTNET_BUILD_CONFIG} -o /out

COPY ./src/${NYS_FQDN}/.manifest /out/.manifest
COPY ./workdir/${NYP_JOBNAME}/releng.json /out/.manifest

# -----------------------------------------------------------------------------
# Container for Publishing Image
# -----------------------------------------------------------------------------
FROM ${DOTNET_RUNTIME_BASE_IMAGE} AS final

# Setting Timezone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /worker

COPY --from=dotnet-build-env /out .

# Execute
ENTRYPOINT [ "dotnet", "/app/NMQ.Core.Router.dll" ]
