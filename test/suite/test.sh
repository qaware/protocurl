set -e

# Test suite: Starts the server and sends multiple requests against it to check the log output

BUILD_PROTOCURL="echo 'Building protocurl...' && docker build -q -t protocurl:v1 -f src/Dockerfile . && echo 'Done.'"

BUILD_SERVER="echo 'Building server...' && docker build -q -t nodeserver:v1 -f test/servers/Dockerfile . && echo 'Done.'"
START_SERVER="echo 'Starting server...' && docker-compose -f test/servers/compose.yml up -d && echo 'Done.'"
STOP_SERVER="echo 'Stopping server...' && docker-compose -f test/servers/compose.yml down && echo 'Done.'"

function isServerReady() {
  rm -rf tmpfile.log || true

  docker-compose -f test/servers/compose.yml logs >tmpfile.log

  if [[ "$?" == 1 ]]; then
    echo "Aborting as server status could not be fetched"
    rm -rf tmpfile.log || true
    exit 1
  fi

  grep -q 'Listening to port' tmpfile.log
}

function ensureServerIsReady() {
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

# todo. fix this, such that the path works for linux via $PWD and for Windows WSL via some hack or so...
export RUN_CLIENT="docker run \
  -v c:/Users/s.sahoo/Documents/QA-Labs-protoCURL/protocurl/test/proto:/proto \
  --network host \
  protocurl:v1 "

function setup() {
  tearDown

  eval $BUILD_PROTOCURL
  eval $BUILD_SERVER
  eval $START_SERVER

  ensureServerIsReady
}

function tearDown() {
  rm -rf tmpfile.log || true
  eval $STOP_SERVER
}

function testSingleRequest() {
  FILENAME="$1"
  ARGS="$2"
  EXPECTED="test/results/$FILENAME-expected.txt"
  OUT="test/results/$FILENAME-out.txt"
  touch "$EXPECTED"
  rm -f "$OUT" || true

  eval "$RUN_CLIENT $ARGS" >"$OUT"

  set +e
  diff --strip-trailing-cr "$EXPECTED" "$OUT" >/dev/null

  if [[ "$?" != 0 ]]; then
    echo "❌❌❌ FAILURE ❌❌❌ - $FILENAME"
    echo "  --- Found difference between expected and actual output ---"
    diff --strip-trailing-cr "$EXPECTED" "$OUT" | sed 's/^/  /'
  else
    echo "✨✨✨ SUCCESS ✨✨✨ - $FILENAME"
  fi

  set -e
}

function runAllTests() {
  echo "=== Running ALL Tests ==="
  rm -rf test/suite/run-testcases.sh || true

  # convert each element in the JSON to the corresponding call of the testSingleRequest function
  JQ_TRANSFORMER=".[] | \"testSingleRequest \(.filename|@sh) \(.args|join(\" \")|@sh)\""
  cat test/suite/testcases.json | test/suite/jq -r "$JQ_TRANSFORMER" >test/suite/run-testcases.sh

  export -f testSingleRequest
  ./test/suite/run-testcases.sh

  echo "=== Finished Running ALL Tests ==="
}

setup
runAllTests
tearDown

#    environment:
# todo. also add documentation on raw text format for request.
# todo. for json support, we need to extend the base image to use the SDK of any programming language to achieve it.
# or perhaps use https://github.com/revinate/protobuf2json directly then? No. We don't know, if it works reliably and has little bugs...
# Let's use protobufjs or the C++ protobuf implementation instead

#      URL: "http://localhost:8080/echo"
#      RESPONSE_TYPE: happyday.HappyDayRequest
#      REQUEST_TXT: 'includeReason: true, date: { seconds: 1648044939, nanos: 152000000 }'
# REQUEST_TXT: 'includeReason: true, date: { seconds: 1234567890102030405, nanos: 50 }'
