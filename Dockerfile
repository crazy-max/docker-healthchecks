# syntax=docker/dockerfile:1

ARG HEALTHCHECKS_VERSION=3.7
ARG ALPINE_VERSION=3.20
ARG S6_VERSION=2.2.0.3

# https://github.com/healthchecks/healthchecks/blob/v3.7/docker/Dockerfile#L1
ARG PYTHON_VERSION=3.12

FROM crazymax/yasu:latest AS yasu
FROM crazymax/alpine-s6-dist:${ALPINE_VERSION}-${S6_VERSION} AS s6

FROM --platform=${BUILDPLATFORM} alpine:${ALPINE_VERSION} AS src
RUN apk add --update git
WORKDIR /src
RUN git init . && git remote add origin "https://github.com/healthchecks/healthchecks"
ARG HEALTHCHECKS_VERSION
RUN git fetch origin "v${HEALTHCHECKS_VERSION}" && git checkout -q FETCH_HEAD

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}
COPY --from=s6 / /
COPY --from=yasu / /
COPY --from=src /src /opt/healthchecks

WORKDIR /opt/healthchecks
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
    pcre2 \
    postgresql-client \
    shadow \
    tzdata \
    zlib \
  && apk --update --no-cache add -t build-dependencies \
    build-base \
    cairo \
    cairo-dev \
    cargo \
    curl-dev \
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
    pcre2-dev \
    postgresql-dev \
    python3-dev \
    zlib-dev \
  && python -m pip install --upgrade pip \
  && pip install apprise minio mysqlclient uwsgi \
  && PYTHONUNBUFFERED=1 pip install --upgrade --no-cache-dir -r requirements.txt \
  && touch hc/local_settings.py \
  && apk del build-dependencies \
  && rm -rf /opt/healthchecks/.git\
    /root/.cache \
    /root/.cargo \
    /tmp/*

COPY rootfs /

ENV TZ="UTC" \
  PUID="1000" \
  PGID="1000"

RUN addgroup -g ${PGID} healthchecks \
  && adduser -D -H -u ${PUID} -G healthchecks -s /bin/sh healthchecks

EXPOSE 8000 2500
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s \
  CMD curl --fail http://127.0.0.1:8000/api/v1/status/ || exit 1
