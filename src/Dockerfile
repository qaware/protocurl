FROM jaegertracing/protobuf:0.3.1
RUN apk --update-cache add wget
RUN cd / && wget --no-check-certificate https://go.dev/dl/go1.18.linux-amd64.tar.gz && ls
# todo. we need to support multiple architectures for the Go download here. -> multi-arch docker images
RUN apk --update-cache add go git
WORKDIR /protocurl
COPY src/*go* /protocurl
RUN go get -d ./...
RUN go build -o protocurl
ENTRYPOINT ["/protocurl/protocurl"]
# todo. use proper docker image via goreleaser instead of this here
