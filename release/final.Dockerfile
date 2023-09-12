FROM gcr.io/distroless/cc:latest as final

WORKDIR /protocurl

COPY --from=builder /usr/bin/curl /usr/bin/curl

# Ideally, we would simply copy these lib files based on their architecture. Unfortunately, we cannot use
# a build arg such as "ARG ARCH_UNAME_M" here with format as given by "uname -m" (x86_64, etc.).
# However, the buildx build command for multi-architecture images only provides TARGETARCH which
# uses go style (amd64, amd32, arm64, etc.). However, we actually want a COPY statement of the form
# COPY --from=builder /lib/$ARCH_UNAME_M-linux-gnu /lib/$ARCH_UNAME_M-linux-gnu
# - which cannot be done with the TARGETARCH build arg. Since the build-arg is set by the enclosing
# buildx command, we cannot intercept it or make our mapping before hand.
# We also cannot first copy to "/lib/amd64-linux-gnu" etc. and then rename the folder,
# because we don't have the linux command "mv" as we are in a distroless context.
# Even if we temporarily copy "mv" from the builder image - it would not work, as it will require
# libraries from /lib/$ARCH_UNAME_M-linux-gnu to run... But these are what we are trying to fix and move in the first place!
# My head exploded.
# Hence, my hack: I decided just to duplicate the folder for each architecture.
# The docker image will be uncessarily large... but one could simply use
# the native CLI for better speed and smaller download size anyways. 

# We only support 64-bit docker images
COPY --from=builder /usr/lib/*-linux-gnu /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/*-linux-gnu /usr/lib/aarch_64-linux-gnu/

COPY --from=builder /lib/*-linux-gnu /lib/x86_64-linux-gnu/
COPY --from=builder /lib/*-linux-gnu /lib/aarch_64-linux-gnu/

COPY --from=builder /lib64*/ld-linux-*.so.2 /lib64/

COPY --from=builder /protocurl/ /protocurl/
ENTRYPOINT ["/protocurl/bin/protocurl"]
