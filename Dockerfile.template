FROM busybox
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT
RUN printf "I'm building for TARGETPLATFORM=${TARGETPLATFORM}" \
    && printf ", TARGETARCH=${TARGETARCH}" \
    && printf ", TARGETVARIANT=${TARGETVARIANT} \n" \
    && printf "With uname -s : " && uname -s \
    && printf "and  uname -m : " && uname -mm
RUN if [[ $TARGETPLATFORM == "linux/amd64" ]]; then \
        s6_platform="amd64" \
    elif [[ $TARGETPLATFORM == "linux/386" ]]; then \
        s6_platform="x86" \
    elif [[ $TARGETPLATFORM == "linux/arm/v6" ]]; then \
        s6_platform="armhf" \
    elif [[ $TARGETPLATFORM == "linux/arm/v7" ]]; then \
        s6_platform="armhf" \
    elif [[ $TARGETPLATFORM == "linux/arm64" ]]; then \
        s6_platform="aarch64" \
    else \
        echo "Platform not supported" \
    fi \
    printf "s6_platform = ${s6_platform}"
