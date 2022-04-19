FROM gcr.io/distroless/cc as final
WORKDIR /protocurl
ARG ARCH_UNAME_M
COPY --from=builder /usr/bin/curl /usr/bin/curl
# this will not quite work with release.yml, as we need to use the architecture based on the TARGETARCH in
COPY --from=builder /usr/lib/${ARCH_UNAME_M}-linux-gnu/ /usr/lib/${ARCH_UNAME_M}-linux-gnu/
COPY --from=builder /lib/${ARCH_UNAME_M}-linux-gnu/ /lib/${ARCH_UNAME_M}-linux-gnu/
COPY --from=builder /protocurl/ /protocurl/
ENTRYPOINT ["/protocurl/bin/protocurl"]
