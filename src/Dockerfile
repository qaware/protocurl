FROM znly/protoc:latest
RUN apk update && apk add -y curl
RUN mkdir -p /proto || true
WORKDIR /protocurl
COPY src/protocurl.sh /protocurl/script.sh
ENTRYPOINT ["/protocurl/script.sh"]