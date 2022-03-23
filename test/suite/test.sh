set -e

# Test suite: Starts the server and sends multiple requests against it to check the log output

BUILD_SERVER="docker build -t nodeserver:v1 -f test/servers/Dockerfile ."
START_SERVER="docker-compose -f test/servers/compose.yml up -d"
STOP_SERVER="docker-compose -f test/servers/compose.yml down"

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

RUN_CLIENT="docker-compose -f test/clients/compose.yml up"
STOP_CLIENT="docker-compose -f test/clients/compose.yml down"

function setup() {
  tearDown
  $BUILD_SERVER
  $START_SERVER

  ensureServerIsReady
}

function tearDown() {
  rm -rf tmpfile.log || true
  $STOP_SERVER
}

function runTests() {
  $RUN_CLIENT >tmpfile.log
  set +e
  grep -q "Tough luck on Wednesday" tmpfile.log

  if [[ "$?" == 1 ]]; then
    echo "❌❌❌ FAILURE ❌❌❌"
    cat tmpfile.log
#    grep -q "Tough luck on Wednesday" tmpfile.log
#    echo "exitcode of grep: $?"
  else
    echo "✨✨✨ SUCCESS ✨✨✨"
#    grep -q "Tough luck on Wednesday" tmpfile.log
#    echo "exitcode of grep: $?"
  fi

  $STOP_CLIENT || true
  set -e
}

setup
runTests
tearDown
