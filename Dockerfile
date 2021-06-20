FROM busybox
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT
RUN printf "I'm building for TARGETPLATFORM=${TARGETPLATFORM}" \
    && printf ", TARGETARCH=${TARGETARCH}" \
    && printf ", TARGETVARIANT=${TARGETVARIANT} \n" \
    && printf "With uname -s : " && uname -s \
    && printf "and  uname -m : " && uname -mm
    
RUN case ${TARGETPLATFORM} in \
         "linux/amd64")  DUPLICACY_ARCH=x64  ;; \
         "linux/arm64")  DUPLICACY_ARCH=arm64  ;; \
         "linux/arm/v7") DUPLICACY_ARCH=arm  ;; \
         "linux/arm/v6") DUPLICACY_ARCH=arm  ;; \
         "linux/386")    DUPLICACY_ARCH=i386   ;; \
    esac \
    && printf "Duplicacy platform ${DUPLICACY_ARCH}"