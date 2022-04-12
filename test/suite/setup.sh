#!/bin/bash

source release/source.sh

buildProtocurl() {
  echo 'Building protocurl...' &&
    docker build -q -t protocurl:latest -f src/local.Dockerfile \
      --build-arg PROTO_VERSION=$PROTO_VERSION --build-arg ARCH=$BUILD_ARCH . &&
    echo 'Done.'
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
}
export -f normaliseOutput