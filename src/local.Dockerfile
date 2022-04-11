FROM debian:11.3-slim
# A developer variant of protocurl for local development. See DEVELOPER.md
ARG PROTO_VERSION
ARG ARCH
RUN apt-get update && apt-get install -y git curl golang
WORKDIR /protocurl
COPY release/tmp/protoc-$PROTO_VERSION-linux-$ARCH/bin/protoc /protocurl/protocurl-internal/bin/protoc
COPY release/tmp/protoc-$PROTO_VERSION-linux-$ARCH/include/ /protocurl/protocurl-internal/include/
COPY src/*go* /protocurl/
RUN go get -d ./...
RUN go build -v -ldflags="-X 'main.version=<version>' -X 'main.commit=<commit>'" -o protocurl
ENTRYPOINT ["/protocurl/protocurl"]
