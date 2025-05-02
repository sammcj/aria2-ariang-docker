FROM alpine:3.21.3

ARG ARIANG_VERSION=1.3.10
ENV ARIANG_VERSION=${ARIANG_VERSION}
ARG BUILD_DATE=latest
ENV BUILD_DATE=${BUILD_DATE}
ARG VCS_REF=main
ENV VCS_REF=${VCS_REF}

ENV ARIA2_RPC_PORT=6800
ENV ARIANG_WEB_PORT=8080

LABEL maintainer="sammcj" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="aria2-ariang" \
    org.label-schema.description="Aria2 downloader and AriaNg webui Docker image based on Alpine Linux" \
    org.label-schema.version=$ARIANG_VERSION \
    org.label-schema.url="https://github.com/sammcj/aria2-ariang-docker" \
    org.label-schema.license="MIT" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/sammcj/aria2-ariang-docker" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vendor="sammcj" \
    org.label-schema.schema-version="1.0"

# Install packages
RUN apk update && \
    apk add --no-cache --update \
    aria2 \
    su-exec \
    curl \
    caddy \
    unzip

# Create Caddyfile directory
RUN mkdir -p /usr/local/caddy

# AriaNG
WORKDIR /usr/local/www/ariang

RUN wget --no-check-certificate https://github.com/mayswind/AriaNg/releases/download/${ARIANG_VERSION}/AriaNg-${ARIANG_VERSION}.zip \
    -O ariang.zip \
    && unzip ariang.zip \
    && rm ariang.zip \
    && chmod -R 755 ./

WORKDIR /aria2

COPY aria2.conf ./conf-copy/aria2.conf
COPY Caddyfile /usr/local/caddy/Caddyfile
COPY start.sh ./
RUN chmod +x ./start.sh

VOLUME /aria2/data
VOLUME /aria2/conf

EXPOSE ${ARIA2_RPC_PORT}
EXPOSE ${ARIANG_WEB_PORT}

ENTRYPOINT ["./start.sh"]
CMD ["--conf-path=/aria2/conf/aria2.conf"]
