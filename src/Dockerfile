FROM debian:11.3-slim
# todo. library and maintainer
RUN apt-get update && apt-get install -y git curl golang
WORKDIR /protocurl
# todo. use corresponding proto version here
# todo. put protoc beside protocurl, since that's how its bundled as non-dockerised CLI.
COPY release/tmp/protoc-3.20.0-linux-x86_64/bin/protoc /usr/bin/protoc
COPY release/tmp/protoc-3.20.0-linux-x86_64/include/ /protocurl/internal/include/
RUN protoc --version
COPY src/*go* /protocurl/
RUN go get -d ./...
RUN go build -o protocurl
ENTRYPOINT ["/protocurl/protocurl"]
