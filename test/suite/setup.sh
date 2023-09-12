#!/bin/bash

source release/source.sh

customNormaliseOutput() { true; }
export -f customNormaliseOutput

PROTOCURL_IMAGE=""
PROTOCURL_IMAGE_ORIGINAL=""
buildProtocurl() {
  set -e
  if [[ "$PROTOCURL_RELEASE_VERSION" != "" ]]; then
    export PROTOCURL_IMAGE_ORIGINAL="qaware/protocurl:$PROTOCURL_RELEASE_VERSION"
    export PROTOCURL_IMAGE="qaware/protocurl:$PROTOCURL_RELEASE_VERSION-test"
    echo "Pulling $PROTOCURL_IMAGE_ORIGINAL ..." && docker pull $PROTOCURL_IMAGE_ORIGINAL && echo "Done."

    customNormaliseOutput() {
      sed -i -E "s/protocurl version .*, build .*,/protocurl version <version>, build <hash>,/g" "$1"
      sed -i -E "s/protocurl [0-9].*, build .*,/protocurl <version>, build <hash>,/g" "$1"
    }
    export -f customNormaliseOutput
  else
    export PROTOCURL_IMAGE_ORIGINAL="protocurl:latest"
    export PROTOCURL_IMAGE="$PROTOCURL_IMAGE_ORIGINAL-test"
    ./dev/generate-local.Dockerfile.sh
    BUILD_ARGS="-q -f dev/generated.local.Dockerfile"
    BUILD_ARGS="$BUILD_ARGS --build-arg PROTO_VERSION=$PROTO_VERSION"
    BUILD_ARGS="$BUILD_ARGS --build-arg ARCH=$BUILD_ARCH"
    BUILD_ARGS="$BUILD_ARGS --build-arg GO_DOWNLOAD_URL_ARCH_TEMPLATE=$GO_DOWNLOAD_URL_ARCH_TEMPLATE"
    echo "Building $PROTOCURL_IMAGE_ORIGINAL ..." &&
      docker build --target final -t $PROTOCURL_IMAGE_ORIGINAL $BUILD_ARGS . &&
      echo "Done."
  fi

  echo "Building test image variant of protocurl including additonal executables ..."
  TMP_DOCKERFILE="test/suite/tmp.Dockerfile"
  echo "" >$TMP_DOCKERFILE
  grep "^FROM " release/builder.Dockerfile >>$TMP_DOCKERFILE
  # add inotify to binaries to test tmp-file permissions. also add pkill for cleanup
  echo "RUN apt-get update && apt-get install -y inotify-tools procps" >>$TMP_DOCKERFILE
  echo "# =============" >>$TMP_DOCKERFILE
  echo "FROM $PROTOCURL_IMAGE_ORIGINAL as final" >>$TMP_DOCKERFILE
  echo "COPY --from=builder /bin/* /bin/" >>$TMP_DOCKERFILE
  echo "COPY --from=builder /usr/bin/* /usr/bin/" >>$TMP_DOCKERFILE
  echo "
COPY --from=builder /lib/*-linux-gnu /lib/x86_64-linux-gnu/
COPY --from=builder /lib/*-linux-gnu /lib/aarch_64-linux-gnu/
COPY --from=builder /usr/lib/*-linux-gnu /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/*-linux-gnu /usr/lib/aarch_64-linux-gnu/
COPY --from=builder /lib64*/ld-linux-*.so.2 /lib64/
  " >>$TMP_DOCKERFILE
  grep "^ENTRYPOINT " release/final.Dockerfile >>$TMP_DOCKERFILE
  remove-leading-spaces-inplace $TMP_DOCKERFILE

  cat $TMP_DOCKERFILE | docker build --target final -t $PROTOCURL_IMAGE -f - .
  echo "Done."
}
export -f buildProtocurl

startServer() {
  echo 'Starting server...' &&
    docker-compose -f test/servers/compose.yml up --build -d >/dev/null 2>&1 &&
    echo 'Done.'
}
export -f startServer

stopServer() {
  echo 'Stopping server...' &&
    docker-compose -f test/servers/compose.yml down >/dev/null 2>&1 &&
    echo 'Done.'
}
export -f stopServer

isServerReady() {
  rm -rf tmpfile.log || true

  docker-compose -f test/servers/compose.yml logs >tmpfile.log

  if [[ "$?" == 1 ]]; then
    echo "Aborting as server status could not be fetched"
    rm -rf tmpfile.log || true
    exit 1
  fi

  grep -q 'Listening to port' tmpfile.log
}
export -f isServerReady

ensureServerIsReady() {
  echo "Waiting for server to become ready..."
  SECONDS=0

  set +e
  until isServerReady; do
    sleep 1s
    echo "Waited $SECONDS seconds already..."
    if ((SECONDS > 20)); then
      echo "Server was not ready within timeout. Aborting"
      exit 1
    fi
  done
  set -e

  rm -rf tmpfile.log || true

  echo "=== Test server is ready ==="
}
export -f ensureServerIsReady

setup() {
  tearDown

  buildProtocurl
  startServer

  ensureServerIsReady
}
export -f setup

tearDown() {
  rm -rf tmpfile.log || true
  stopServer
}
export -f tearDown

export NORMALISED_ASPECTS="date, text format indentation, tmp-filenames, newlines"
normaliseOutput() {
  # normalise line endings
  sed -i 's/^M$//g' "$1"

  # replace UTF-8 non-breaking spaces (C2 A0) sometimes produced by protoc
  sed -i 's/\xC2\xA0/ /g' "$1"

  # test text format is sometimes unstable and serialises to "<field>: <value>" or "<field>:  <value>" randomly
  # But this difference does not actually matter, hence we normalise this away.
  sed -i "s/:  /: /g" "$1"
  # The same happens for separators in JSON.
  sed -i 's/, "/,"/g' "$1"
  sed -i 's/,  "/,"/g' "$1"
  sed -i 's/, {/,{/g' "$1"
  sed -i 's/,  {/,{/g' "$1"

  # remove lines with random temporary folder names
  sed -i "s|/tmp/protocurl-temp.*|<tmp>|g" "$1"

  customNormaliseOutput "$1"
}
export -f normaliseOutput

meaningfulDiff() {
  normaliseOutput "$1"
  normaliseOutput "$2"
  diff -I 'Date: .*' --strip-trailing-cr "$1" "$2"
}
export -f meaningfulDiff

remove-leading-spaces-inplace() {
  sed -i 's/^[ \t]*//' "$1"
}
export -f remove-leading-spaces-inplace
