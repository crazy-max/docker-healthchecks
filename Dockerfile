FROM --platform=${TARGETPLATFORM:-linux/amd64} python:3.8-alpine3.12 as s6

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a)\n"

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ENV JUSTC_ENVDIR_VERSION="1.0.0" \
  SOCKLOG_VERSION="2.2.1" \
  SOCKLOG_RELEASE="5" \
  S6_OVERLAY_PREINIT_VERSION="1.0.2" \
  S6_OVERLAY_VERSION="2.1.0.0" \
  DIST_PATH="/dist"

RUN apk --update --no-cache add \
    autoconf \
    automake \
    binutils \
    build-base \
    curl \
    rsync \
    skalibs-dev \
    tar \
    tree

WORKDIR /tmp/justc-envdir
RUN curl -sSL "https://github.com/just-containers/justc-envdir/releases/download/v${JUSTC_ENVDIR_VERSION}/justc-envdir-${JUSTC_ENVDIR_VERSION}.tar.gz" | tar xz --strip 1 \
  && ./configure \
    --enable-shared \
    --disable-allstatic \
    --prefix=/usr \
  && make -j$(nproc) \
  && make DESTDIR=${DIST_PATH} install \
  && tree ${DIST_PATH}

WORKDIR /tmp/socklog
RUN curl -sSL "https://github.com/just-containers/socklog/releases/download/v${SOCKLOG_VERSION}-${SOCKLOG_RELEASE}/socklog-${SOCKLOG_VERSION}.tar.gz" | tar xz --strip 1 \
  && ./configure \
    --enable-shared \
    --disable-allstatic \
    --prefix=/usr \
  && make -j$(nproc) \
  && make DESTDIR=${DIST_PATH} install \
  && tree ${DIST_PATH}

WORKDIR /tmp/s6-overlay-preinit
RUN curl -sSL "https://github.com/just-containers/s6-overlay-preinit/releases/download/v${S6_OVERLAY_PREINIT_VERSION}/s6-overlay-preinit-${S6_OVERLAY_PREINIT_VERSION}.tar.gz" | tar xz --strip 1 \
  && ./configure \
    --enable-shared \
    --disable-allstatic \
  && make -j$(nproc) \
  && make DESTDIR=${DIST_PATH} install \
  && tree ${DIST_PATH}

WORKDIR /tmp/s6-overlay
RUN curl -SsOL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-nobin.tar.gz \
  && tar zxf s6-overlay-nobin.tar.gz -C ${DIST_PATH}/

WORKDIR /tmp/socklog-overlay
RUN wget -q "https://github.com/just-containers/socklog-overlay/archive/master.zip" -qO "socklog-overlay.zip" \
  && unzip socklog-overlay.zip \
  && rsync -a ./socklog-overlay-master/overlay-rootfs/ ${DIST_PATH}/ \
  && mkdir -p ${DIST_PATH}/var/log/socklog/cron \
    ${DIST_PATH}/var/log/socklog/daemon \
    ${DIST_PATH}/var/log/socklog/debug \
    ${DIST_PATH}/var/log/socklog/errors \
    ${DIST_PATH}/var/log/socklog/everything \
    ${DIST_PATH}/var/log/socklog/kernel \
    ${DIST_PATH}/var/log/socklog/mail \
    ${DIST_PATH}/var/log/socklog/messages \
    ${DIST_PATH}/var/log/socklog/secure \
    ${DIST_PATH}/var/log/socklog/user \
  && tree ${DIST_PATH}

FROM --platform=${TARGETPLATFORM:-linux/amd64} python:3.8-alpine3.12

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL maintainer="CrazyMax" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.url="https://github.com/crazy-max/docker-healthchecks" \
  org.opencontainers.image.source="https://github.com/crazy-max/docker-healthchecks" \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.revision=$VCS_REF \
  org.opencontainers.image.vendor="CrazyMax" \
  org.opencontainers.image.title="Healthchecks" \
  org.opencontainers.image.description="Cron Monitoring Tool" \
  org.opencontainers.image.licenses="MIT"

RUN apk --update --no-cache add \
    s6 \
    s6-dns \
    s6-linux-utils \
    s6-networking \
    s6-portable-utils \
    s6-rc \
  && s6-rmrf /var/cache/apk/* /tmp/*

COPY --from=s6 /dist /

ENV HEALTHCHECKS_VERSION="1.16.0" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

RUN apk --update --no-cache add \
    bash \
    curl \
    jansson \
    libcap \
    libressl \
    libxml2 \
    mailcap \
    mariadb-client \
    musl \
    pcre \
    postgresql-client \
    shadow \
    su-exec \
    tzdata \
    zlib \
  && apk --update --no-cache add -t build-dependencies \
    build-base \
    gcc \
    git \
    jansson-dev \
    libcap-dev \
    libressl-dev \
    libxml2-dev \
    linux-headers \
    mariadb-dev \
    musl-dev \
    pcre-dev \
    postgresql-dev \
    zlib-dev \
  && cd /opt \
  && git clone --branch v${HEALTHCHECKS_VERSION} "https://github.com/healthchecks/healthchecks" healthchecks \
  && cd healthchecks \
  && pip install mysqlclient uwsgi \
  && pip install --upgrade --no-cache-dir -r requirements.txt \
  && touch hc/local_settings.py \
  && apk del build-dependencies \
  && rm -rf /opt/healthchecks/.git /root/.cache /tmp/* /var/cache/apk/*

COPY rootfs /

RUN addgroup -g ${PGID} healthchecks \
  && adduser -D -H -u ${PUID} -G healthchecks -s /bin/sh healthchecks

EXPOSE 8000 2500
WORKDIR /opt/healthchecks
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s \
  CMD curl --fail http://127.0.0.1:8000/api/v1/status/ || exit 1
