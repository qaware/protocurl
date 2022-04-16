FROM debian:stable-slim
ARG VERSION
ARG TARGETARCH
RUN apt-get -q update && \
    apt-get -q install -y curl unzip \
    zlib1g=1:1.2.11.dfsg-2+deb11u1 # CVE-2018-25032
WORKDIR /protocurl
COPY LICENSE.md README.md ./
COPY dist/protocurl_${VERSION}_linux_${TARGETARCH}.zip ./
RUN unzip *.zip && rm -f *.md *.zip && ls -lh . && apt-get -q purge -y unzip
ENTRYPOINT ["/protocurl/bin/protocurl"]
