ARG HEALTHCHECKS_VERSION=2.1

FROM crazymax/yasu:latest AS yasu
FROM crazymax/alpine-s6-dist:3.17-2.2.0.3 AS s6
FROM python:3.10-alpine3.17

ENV TZ="UTC" \
  PUID="1000" \
  PGID="1000"

ARG HEALTHCHECKS_VERSION
RUN apk --update --no-cache add \
    bash \
    bearssl \
    curl \
    jansson \
    libcap \
    libffi \
    libpq \
    libxml2 \
    mailcap \
    mariadb-client \
    musl \
    openssl \
    pcre \
    postgresql-client \
    shadow \
    tzdata \
    zlib \
  && apk --update --no-cache add -t build-dependencies \
    build-base \
    cairo \
    cairo-dev \
    cargo \
    gcc \
    git \
    jansson-dev \
    libcap-dev \
    libffi-dev \
    libpq-dev \
    libxml2-dev \
    linux-headers \
    mariadb-dev \
    musl-dev \
    openssl-dev \
    pcre-dev \
    postgresql-dev \
    python3-dev \
    zlib-dev \
  && mkdir -p ~/.cargo/registry/index \
  && cd ~/.cargo/registry/index \
  && git clone --bare https://github.com/rust-lang/crates.io-index.git github.com-1285ae84e5963aae \
  && cd /opt \
  && git clone --branch v${HEALTHCHECKS_VERSION} "https://github.com/healthchecks/healthchecks" healthchecks \
  && cd healthchecks \
  && python -m pip install --upgrade pip \
  && pip install apprise minio mysqlclient uwsgi \
  && PYTHONUNBUFFERED=1 pip install --upgrade --no-cache-dir -r requirements.txt \
  && touch hc/local_settings.py \
  && apk del build-dependencies \
  && rm -rf /opt/healthchecks/.git /root/.cache /root/.cargo /tmp/*

COPY --from=s6 / /
COPY --from=yasu / /
COPY rootfs /

RUN addgroup -g ${PGID} healthchecks \
  && adduser -D -H -u ${PUID} -G healthchecks -s /bin/sh healthchecks

EXPOSE 8000 2500
WORKDIR /opt/healthchecks
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s \
  CMD curl --fail http://127.0.0.1:8000/api/v1/status/ || exit 1
