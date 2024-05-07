ARG USER_NAME='app'
ARG USER_UID='1000'
ARG USER_GID='1000'
ARG USER_GROUP='app_users'
ARG REPO='githunb.com/b01/dl-vscode-server'
ARG WD="/home/${USER_NAME}/src/${REPO}/test/alpine"

# VS Code, unfortunately, relies on GNU Lib C. So see if we can use Kohirens Alpine GNU LibC image.
FROM alpine:3.19

ARG USER_NAME
ARG USER_UID
ARG USER_GID
ARG USER_GROUP
ARG REPO
ARG WD

RUN apk --no-progress --purge --no-cache upgrade \
 && apk --no-progress --purge --no-cache add --upgrade \
    bash \
    curl \
    musl \
    libgcc \
    libstdc++ \
    openssh \
    python3 \
&& apk --no-progress --purge --no-cache upgrade \
 && rm -vrf /var/cache/apk/*
#
## Add a non-root group and user to runas
#RUN addgroup --system --gid ${USER_GID} ${USER_GROUP} \
# && adduser --system \
#    --disabled-password \
#    --ingroup ${USER_GROUP} \
#    --uid ${USER_UID} \
#    ${USER_NAME}
#
#USER ${USER_NAME}
#
COPY --chmod=${USER_NAME}:${USER_NAME} test/alpine/start.sh /usr/local/bin

HEALTHCHECK --interval=5m --timeout=3s \
  CMD echo "healthy" || exit 1

ENTRYPOINT [ "start.sh" ]

COPY --chmod=${USER_NAME}:${USER_NAME} download-vs-code-server.sh /tmp

# Install VS Code Server
RUN /tmp/download-vs-code-server.sh "alpine" "x64" "yes"
#
#WORKDIR ${WD}
#SHELL [ "/bin/bash", "-c" ]