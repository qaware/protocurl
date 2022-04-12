FROM debian:11.3-slim
ARG VERSION
ARG TARGETARCH
RUN apt-get update && apt-get install -y curl unzip
WORKDIR /protocurl
COPY dist/protocurl_${VERSION}_linux_${TARGETARCH}.zip ./
RUN unzip *.zip && rm -f *.md *.zip && ls -lh .
ENTRYPOINT ["/protocurl/bin/protocurl"]
