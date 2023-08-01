set -e

# Test suite: Starts the server and sends multiple requests against it to check the log output

WORKING_DIR="$1"

if [[ "$WORKING_DIR" == "" ]]; then
  echo "Please provide the working directory as a a docker-mount friendly path."
  exit 1
fi

export RUN_CLIENT="docker run --rm -v $WORKING_DIR/test/proto:/proto --network host"

export SHOW_LOGS="docker logs"

export TESTS_SUCCESS="true"

source test/suite/setup.sh

testSingleRequest() {
  FILENAME="$1"
  ARGS="$2"
  BEFORE_TEST_BASH="$3"
  RUN_AGAIN_WITH_ARG="$4"
  AFTER_TEST_BASH="$5"

  if [[ "$FILENAME" == "response-type-arg-overidden-decode-raw" && "$(uname)" == *"MINGW"* ]]; then
    echo "🚧🚧🚧 SKIPPED 🚧🚧🚧 - Skipping response-type-arg-overidden-decode-raw on Windows due to special circumstances."
    return 0
  fi

  if [[ "$RUN_AGAIN_WITH_ARG" != "" ]]; then
    NEW_ARGS="$RUN_AGAIN_WITH_ARG $ARGS"
    NEW_FILENAME="${FILENAME}-${RUN_AGAIN_WITH_ARG#--}"
    testSingleRequest "$FILENAME" "$ARGS" "$BEFORE_TEST_BASH" "" "$AFTER_TEST_BASH"
    testSingleRequest "$NEW_FILENAME" "$NEW_ARGS" "$BEFORE_TEST_BASH" "" "$AFTER_TEST_BASH"
  else

    EXPECTED="test/results/$FILENAME-expected.txt"
    OUT="test/results/$FILENAME-out.txt"
    OUT_ERR="test/results/$FILENAME-out-err-tmp.txt"
    touch "$EXPECTED"
    rm -f "$OUT" || true
    rm -f "$OUT_ERR" || true
    echo "######### STDOUT #########" >"$OUT"
    EXIT_CODE="?"

    set +e

    if [[ "$BEFORE_TEST_BASH" == "" && "$AFTER_TEST_BASH" == "" ]]; then
      eval "$RUN_CLIENT --name $FILENAME $PROTOCURL_IMAGE $ARGS" 2>"$OUT_ERR" >>"$OUT"
      EXIT_CODE="$?"
    else
      if [[ "$BEFORE_TEST_BASH" == "" ]]; then BEFORE_TEST_BASH="true"; fi
      if [[ "$AFTER_TEST_BASH" == "" ]]; then AFTER_TEST_BASH="true"; fi
      ARGS="$(echo "$ARGS" | sed 's/"/\\"/g')" # escape before usage inside quoted context
      eval "$RUN_CLIENT --entrypoint bash \
        --name $FILENAME $PROTOCURL_IMAGE \
        -c \"$BEFORE_TEST_BASH && ./bin/protocurl $ARGS && $AFTER_TEST_BASH\"" \
        2>"$OUT_ERR" >>"$OUT"
      EXIT_CODE="$?"
    fi
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

  fi
}

runAllTests() {
  echo "=== Running ALL Tests ==="
  rm -f ./test/suite/run-testcases.sh || true

  # Convert each element in the JSON to the corresponding call of the testSingleRequest function.
  # Simply look at the produced run-testcases.sh file to see what it looks like.
  CONVERT_TESTCASE_TO_SINGLE_TEST_INVOCATION=".[] | \"testSingleRequest \(.filename|@sh) \(.args|join(\" \")|@sh) \(.beforeTestBash // \"\"|@sh) \(.runAgainWithArg // \"\"|@sh) \(.afterTestBash // \"\"|@sh)\""
  cat test/suite/testcases.json | jq -r "$CONVERT_TESTCASE_TO_SINGLE_TEST_INVOCATION" >./test/suite/run-testcases.sh

  export -f testSingleRequest
  chmod +x ./test/suite/run-testcases.sh
  source ./test/suite/run-testcases.sh

  echo "=== Finished Running ALL Tests ==="
}

setup
runAllTests
tearDown

eval "$TESTS_SUCCESS"
