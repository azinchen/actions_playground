FROM alpine:latest AS builder

ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz

RUN echo "**** upgrade packages ****" && \
    apk --no-cache --no-progress upgrade && \
    echo "**** install packages ****" && \
    apk --no-cache --no-progress add tar && \
    echo "**** create folders ****" && \
    mkdir -p /s6 && \
    echo "**** extract s6 overlay ****" && \
    tar xfz /tmp/s6-overlay.tar.gz -C /s6/

FROM alpine:latest

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV BACKUP_CRON="" \
    SNAPSHOT_ID="" \
    STORAGE_URL="" \
    PRIORITY_LEVEL=10 \
    EMAIL_LOG_LINES_IN_BODY=10

ADD https://github.com/gilbertchen/duplicacy/releases/latest/download/duplicacy_linux_x64_env.NEW_S6_OVERLAY_VERSION /usr/bin/duplicacy

RUN echo "**** upgrade packages ****" && \
    apk --no-cache --no-progress upgrade && \
    echo "**** install packages ****" && \
    apk --no-cache --no-progress add bash zip ssmtp ca-certificates docker && \
    echo "**** add duplicacy binary ****" && \
    chmod +x /usr/bin/duplicacy && \
    echo "**** create folders ****" && \
    mkdir -p /config && \
    mkdir -p /data && \
    echo "**** cleanup ****" && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/*

COPY --from=builder /s6/ /
COPY root/ /

RUN chmod +x /app/*

VOLUME ["/config"]
VOLUME ["/data"]

WORKDIR  /config

ENTRYPOINT ["/init"]