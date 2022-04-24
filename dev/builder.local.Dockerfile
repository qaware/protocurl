FROM debian:stable-slim as builder
# A developer variant of protocurl for local development. See DEVELOPER.md
# This should be kept in sync with release/builder.Dockerfile

ARG PROTO_VERSION
ARG ARCH
ARG GO_DOWNLOAD_URL_ARCH_TEMPLATE

RUN apt-get -q update  && apt-get -q install -y git curl 
COPY release/20-install-go.sh /install-go.sh
RUN export URL="$(echo $GO_DOWNLOAD_URL_ARCH_TEMPLATE | sed "s/__ARCH__/$ARCH/g")"; /install-go.sh "$URL" this-is-not-my-development-computer

WORKDIR /protocurl
COPY release/tmp/protoc-$PROTO_VERSION-linux-$ARCH/bin/protoc /protocurl/protocurl-internal/bin/protoc
COPY release/tmp/protoc-$PROTO_VERSION-linux-$ARCH/include/ /protocurl/protocurl-internal/include/
COPY src/*go* /protocurl/

RUN go get -d ./...
RUN go build -v -ldflags="-X 'main.version=<version>' -X 'main.commit=<hash>'" -o bin/protocurl
RUN rm -rf *go*
