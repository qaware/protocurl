#!/bin/bash

source release/source.sh

PROTOCURL_IMAGE=""
buildProtocurl() {
  if [[ "$PROTOCURL_RELEASE_VERSION" != "" ]]; then
    export PROTOCURL_IMAGE="qaware/protocurl:$PROTOCURL_RELEASE_VERSION"
    echo "Pulling $PROTOCURL_IMAGE ..." && docker pull $PROTOCURL_IMAGE && echo "Done."

    customNormaliseOutput() {
      sed -i -E "s/protocurl version .*, build .*,/protocurl version <version>, build <hash>,/g" "$1"
      sed -i -E "s/protocurl [0-9].*, build .*,/protocurl <version>, build <hash>,/g" "$1"
    }
    export -f customNormaliseOutput
  else
    export PROTOCURL_IMAGE="protocurl:latest"
    echo "Building $PROTOCURL_IMAGE ..." &&
      docker build -q -t $PROTOCURL_IMAGE -f src/local.Dockerfile \
        --build-arg PROTO_VERSION=$PROTO_VERSION --build-arg ARCH=$BUILD_ARCH . &&
      echo "Done."

    customNormaliseOutput() { true; }
    export -f customNormaliseOutput
  fi
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

export NORMALISED_ASPECTS="date, go traceback, text format indentation"
normaliseOutput() {
  # normalise line endings
  sed -i 's/^M$//g' "$1"

  # deletes all lines starting at a go traceback
  sed -i '/goroutine 1.*/,$d' "$1"

  # test text format is sometimes unstable and serialises to "<field>: <value>" or "<field>:  <value>" randomly
  # But this difference does not actually matter, hence we normalise this away.
  sed -i "s/:  /: /g" "$1"
  # The same happens for separators in JSON.
  sed -i 's/, "/,"/g' "$1"
  sed -i 's/,  "/,"/g' "$1"
  sed -i 's/, {/,{/g' "$1"
  sed -i 's/,  {/,{/g' "$1"

  # remove lines with random tamporary folder names
  sed -i "s|/tmp/protocurl-temp.*|<tmp>|g" "$1"

  customNormaliseOutput "$1"
}
export -f normaliseOutput
