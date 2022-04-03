FROM jaegertracing/protobuf:0.3.1
RUN apk --update-cache add go git curl
WORKDIR /protocurl
COPY src/*go* /protocurl/
RUN go get -d ./...
RUN go build -o protocurl
ENTRYPOINT ["/protocurl/protocurl"]
# todo. use proper docker image via goreleaser instead of this here
