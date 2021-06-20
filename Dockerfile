FROM alpine:latest AS s6-builder

ARG TARGETPLATFORM

RUN echo "**** upgrade packages ****" \
    && apk --no-cache --no-progress upgrade \
    && echo "**** install packages ****" \
    && apk --no-cache --no-progress add tar curl ca-certificates \
    && echo "**** create folders ****" \
    && mkdir -p /s6 \
    && echo "**** download s6 overlay ****"
RUN case ${TARGETPLATFORM} in \
        "linux/amd64")  s6_platform=amd64  ;; \
        "linux/arm64")  s6_platform=aarch64  ;; \
        "linux/arm/v7") s6_platform=armhf  ;; \
        "linux/arm/v6") s6_platform=arm  ;; \
        "linux/386")    s6_platform=x86   ;; \
    esac \
    && curl  https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-$s6_platform.tar.gz -o /tmp/s6-overlay.tar.gz \
    && echo "**** extract s6 overlay ****" \
    && tar xfz /tmp/s6-overlay.tar.gz -C /s6/

FROM alpine:latest AS duplicacy-builder

ARG TARGETPLATFORM
ARG DUPLICACY_VERSION

RUN echo "**** upgrade packages ****" \
    && apk --no-cache --no-progress upgrade \
    && echo "**** install packages ****" \
    && apk --no-cache --no-progress add curl ca-certificates \
    && echo "**** create folders ****" \
    && mkdir -p /s6 \
    && echo "**** download duplicacy ****"
RUN case ${TARGETPLATFORM} in \
        "linux/amd64")  duplicacy_platform=x64  ;; \
        "linux/arm64")  duplicacy_platform=arm64  ;; \
        "linux/arm/v7") duplicacy_platform=arm  ;; \
        "linux/arm/v6") duplicacy_platform=arm  ;; \
        "linux/386")    duplicacy_platform=i386   ;; \
    esac \
    && echo "Duplicacy platform selected "$duplicacy_platform \
    && curl  https://github.com/gilbertchen/duplicacy/releases/latest/download/duplicacy_linux_$duplicacy_platform_$DUPLICACY_VERSION -o /tmp/duplicacy

FROM alpine:latest

LABEL maintainer="Alexander Zinchenko <alexander@zinchenko.com>"

ENV BACKUP_CRON="" \
    SNAPSHOT_ID="" \
    STORAGE_URL="" \
    PRIORITY_LEVEL=10 \
    EMAIL_LOG_LINES_IN_BODY=10

RUN echo "**** upgrade packages ****" \
    && apk --no-cache --no-progress upgrade \
    && echo "**** install packages ****" \
    && apk --no-cache --no-progress add bash zip ssmtp ca-certificates docker \
    && echo "**** create folders ****" \
    && mkdir -p /config \
    && mkdir -p /data \
    && echo "**** cleanup ****" \
    && rm -rf /tmp/* \
    && rm -rf /var/cache/apk/*

COPY --from=s6-builder /s6/ /
COPY --from=duplicacy-builder /tmp/duplicacy /usr/bin/duplicacy
COPY root/ /

RUN chmod +x /app/* \
    chmod +x /usr/bin/duplicacy

VOLUME ["/config"]
VOLUME ["/data"]

WORKDIR  /config

ENTRYPOINT ["/init"]
