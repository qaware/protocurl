FROM znly/protoc:latest
# todo. perhaps use base image this? https://github.com/namely/docker-protoc
RUN apk update && apk add -y curl
RUN mkdir -p /proto || true
WORKDIR /protocurl
COPY src/protocurl.sh /protocurl/script.sh
ENTRYPOINT /protocurl/script.sh /proto