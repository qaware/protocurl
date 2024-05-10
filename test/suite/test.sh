#!/bin/bash

set -euo pipefail

# Test suite: Starts the server and sends multiple requests against it to check the log output

if [[ "$#" == 0 ]]; then
  echo "Please provide the working directory as a a docker-mount friendly path."
  exit 1
fi

WORKING_DIR="$1"

export RUN_CLIENT="docker run --rm -v $WORKING_DIR/test/proto:/proto -v $WORKING_DIR/test/payloads:/payloads --network host"

export SHOW_LOGS="docker logs"

export TESTS_SUCCESS="true"

source test/suite/setup.sh

testSingleRequest() {
  # use local variables to avoid collision with other functions
  local FILENAME="$1"
  local ARGS="$2"
  local BEFORE_TEST_BASH="$3"
  local AFTER_TEST_BASH="$4"

  if [[ "$FILENAME" == "response-type-arg-overidden-decode-raw"* && "$(uname)" == *"MINGW"* ]]; then
    echo "🚧🚧🚧 SKIPPED 🚧🚧🚧 - $FILENAME skipped on Windows due to special circumstances."
    return 0
  fi

  EXPECTED="test/results/$FILENAME-expected.txt"
  OUT="test/results/$FILENAME-out.txt"
  OUT_ERR="test/results/$FILENAME-out-err-tmp.txt"
  touch "$EXPECTED"
  rm -f "$OUT" || true
  rm -f "$OUT_ERR" || true
  docker rm -f "$FILENAME" >/dev/null 2>&1 || true # stop any previously running container for this testcase
  EXIT_CODE="?"                                    # default exit code, if process aborts abnormaly

  echo "######### STDOUT #########" >"$OUT"

  set +e

  if [[ "$BEFORE_TEST_BASH" == "" ]]; then BEFORE_TEST_BASH="true"; fi
  if [[ "$AFTER_TEST_BASH" == "" ]]; then AFTER_TEST_BASH="true"; fi

  eval "$RUN_CLIENT --entrypoint bash \
    --name $FILENAME $PROTOCURL_IMAGE \
    -c '$BEFORE_TEST_BASH && ./bin/protocurl $ARGS && $AFTER_TEST_BASH'" \
    2>"$OUT_ERR" >>"$OUT"
  EXIT_CODE="$?"

  echo "######### STDERR #########" >>"$OUT"
  cat "$OUT_ERR" >>"$OUT"

  echo "######### EXIT $EXIT_CODE #########" >>"$OUT"

  meaningfulDiff "$EXPECTED" "$OUT" >/dev/null

  if [[ "$?" != 0 ]]; then
    export TESTS_SUCCESS="false"
    echo "❌❌❌ FAILURE ❌❌❌ - $FILENAME"
    echo "=== Found difference between expected and actual output (ignoring $NORMALISED_ASPECTS) ==="
    meaningfulDiff "$EXPECTED" "$OUT" | sed 's/^/  /'
    echo "The actual output was saved into $OUT for inspection."
  else
    echo "✨✨✨ SUCCESS ✨✨✨ - $FILENAME"
  fi

  set -e

  rm -f "$OUT_ERR" || true
}

# A spec consists of potentially many single requests.
testSingleSpec() {
  # use local variables to avoid collision with other functions
  local FILENAME="$1"
  local ARGS="$2"
  local BEFORE_TEST_BASH="$3"
  local AFTER_TEST_BASH="$4"

  testSingleRequest "$FILENAME" "$ARGS" "$BEFORE_TEST_BASH" "$AFTER_TEST_BASH"
  shift 4
  for extra_arg in "$@"; do
    local NEW_FILENAME="${FILENAME}-${extra_arg#--}"
    NEW_FILENAME="$(echo "$NEW_FILENAME" | sed 's/ /_/g' | sed 's/\./_/g')" # sanitise filename
    testSingleRequest "$NEW_FILENAME" "$extra_arg $ARGS" "$BEFORE_TEST_BASH" "$AFTER_TEST_BASH"
  done
}

runAllTests() {
  echo "=== Running ALL Tests ==="
  rm -f ./test/suite/run-testcases.sh || true

  # Convert each element in the JSON to the corresponding call of the testSingleRequest function.
  # Simply look at the produced run-testcases.sh file to see what it looks like.
  CONVERT_TESTCASE_TO_SINGLE_TEST_INVOCATION=".[] | \"testSingleSpec \(.filename|@sh) \(.args|join(\" \")|@sh) \(.beforeTestBash // \"\"|@sh) \(.afterTestBash // \"\"|@sh) \((.rerunwithArgForEachElement // [])|@sh)\""
  cat test/suite/testcases.json \
    | jq -r "$CONVERT_TESTCASE_TO_SINGLE_TEST_INVOCATION" \
    >./test/suite/run-testcases.sh

  export -f testSingleSpec
  export -f testSingleRequest
  chmod +x ./test/suite/run-testcases.sh
  source ./test/suite/run-testcases.sh

  echo "=== Finished Running ALL Tests ==="
}

setup
runAllTests
tearDown

eval "$TESTS_SUCCESS"
