FROM library/golang:1.18.0-alpine3.15
WORKDIR /protocurl
COPY src/*go* /protocurl
RUN go build -o protocurl
ENTRYPOINT ["/protocurl/protocurl"]
# todo. use proper docker image via goreleaser instead of this here