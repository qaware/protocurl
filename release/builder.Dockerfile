# This should be kept in sync with dev/builder.local.Dockerfile

FROM debian:stable-slim as builder
ARG VERSION
ARG TARGETARCH
RUN apt-get -q update && \
    apt-get -q install -y curl unzip zlib1g
WORKDIR /protocurl
COPY dist/protocurl_${VERSION}_linux_${TARGETARCH}.zip ./
RUN unzip *.zip && rm -f *.md *.zip && ls -lh . && apt-get -q purge -y unzip
COPY LICENSE.md README.md ./
