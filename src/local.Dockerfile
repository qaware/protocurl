FROM debian:11.3-slim
# A developer variant of protocurl for local development. For this, one needs to run release/get-protoc-binaries.sh first.
RUN apt-get update && apt-get install -y git curl golang
WORKDIR /protocurl
# todo. use corresponding proto version here
COPY release/tmp/protoc-3.20.0-linux-x86_64/bin/protoc /protocurl/protocurl-internal/bin/protoc
COPY release/tmp/protoc-3.20.0-linux-x86_64/include/ /protocurl/protocurl-internal/include/
COPY src/*go* /protocurl/
RUN go get -d ./...
RUN go build -v -ldflags="-X 'main.version=<version>' -X 'main.commit=<commit>'" -o protocurl
ENTRYPOINT ["/protocurl/protocurl"]
