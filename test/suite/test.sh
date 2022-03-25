set -e

# Test suite: Starts the server and sends multiple requests against it to check the log output

WORKING_DIR="$1"

BUILD_PROTOCURL="echo 'Building protocurl...' && docker build -q -t protocurl:latest -f src/Dockerfile . && echo 'Done.'"

START_SERVER="echo 'Starting server...' && docker-compose -f test/servers/compose.yml up --build -d && echo 'Done.'"
STOP_SERVER="echo 'Stopping server...' && docker-compose -f test/servers/compose.yml down && echo 'Done.'"

export RUN_CLIENT="docker run -v $WORKING_DIR/test/proto:/proto --network host"

export SHOW_LOGS="docker logs"

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

setup() {
  tearDown

  eval $BUILD_PROTOCURL
  eval $START_SERVER

  ensureServerIsReady
}

tearDown() {
  rm -rf tmpfile.log || true
  eval $STOP_SERVER
}

testSingleRequest() {
  FILENAME="$1"
  ARGS="$2"
  EXPECTED="test/results/$FILENAME-expected.txt"
  OUT="test/results/$FILENAME-out.txt"
  touch "$EXPECTED"
  sed -i 's/^M$//' "$EXPECTED" # normalise line endings
  rm -f "$OUT" || true

  set +e

  eval "docker rm -f $FILENAME > /dev/null"
  eval "$RUN_CLIENT --name $FILENAME protocurl $ARGS" | sed 's/^M$//' >"$OUT"

  diff -I 'Date: .*'  --strip-trailing-cr "$EXPECTED" "$OUT" >/dev/null

  if [[ "$?" != 0 ]]; then
    echo "❌❌❌ FAILURE ❌❌❌ - $FILENAME"
    echo "Docker logs:"
    eval "$SHOW_LOGS $FILENAME" | sed 's/^/  /'
    echo "  --- Found difference between expected and actual output ---"
    diff --strip-trailing-cr "$EXPECTED" "$OUT" | sed 's/^/  /'
    echo "The actual output was saved into $OUT for inspection."
  else
    echo "✨✨✨ SUCCESS ✨✨✨ - $FILENAME"
  fi

  set -e
}

runAllTests() {
  echo "=== Running ALL Tests ==="
  rm -rf ./test/suite/run-testcases.sh || true

  # Convert each element in the JSON to the corresponding call of the testSingleRequest function.
  # Simply look at the produced run-testcases.sh file to see what it looks like.
  CONVERT_TESTCASE_TO_SINGLE_TEST_INVOCATION=".[] | \"testSingleRequest \(.filename|@sh) \(.args|join(\" \")|@sh)\""
  cat test/suite/testcases.json | test/suite/jq -r "$CONVERT_TESTCASE_TO_SINGLE_TEST_INVOCATION" >./test/suite/run-testcases.sh

  export -f testSingleRequest
  ./test/suite/run-testcases.sh

  echo "=== Finished Running ALL Tests ==="
}

setup
runAllTests
tearDown
