set -e

# Test suite: Starts the server and sends multiple requests against it to check the log output

WORKING_DIR="$1"

export RUN_CLIENT="docker run --rm -v $WORKING_DIR/test/proto:/proto --network host \
  -v /bin/bash:/bin/bash:ro \
  -v /bin/mkdir:/bin/mkdir:ro \
  -v /bin/cp:/bin/cp:ro \
  -v /bin/mv:/bin/mv:ro \
  -v /bin/rm:/bin/rm:ro \
  -v /bin/sed:/bin/sed:ro \
  -v /bin/chmod:/bin/chmod:ro"
# We also mount the utilities into the distroless container to make them useable in the tests

export SHOW_LOGS="docker logs"

export TESTS_SUCCESS="true"

source test/suite/setup.sh

testSingleRequest() {
  FILENAME="$1"
  ARGS="$2"
  BEFORE_TEST_BASH="$3"
  RUN_AGAIN_WITH_ARG="$4"

  if [[ "$RUN_AGAIN_WITH_ARG" != "" ]]; then
    NEW_ARGS="$RUN_AGAIN_WITH_ARG $ARGS"
    NEW_FILENAME="${FILENAME}-${RUN_AGAIN_WITH_ARG#--}"
    testSingleRequest "$FILENAME" "$ARGS" "$BEFORE_TEST_BASH" ""
    testSingleRequest "$NEW_FILENAME" "$NEW_ARGS" "$BEFORE_TEST_BASH" ""
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

    if [[ "$BEFORE_TEST_BASH" == "" ]]; then
      eval "$RUN_CLIENT --name $FILENAME $PROTOCURL_IMAGE $ARGS" 2>"$OUT_ERR" >>"$OUT"
      EXIT_CODE="$?"
    else
      ARGS="$(echo "$ARGS" | sed 's/"/\\"/g')" # escape before usage inside quoted context
      eval "$RUN_CLIENT --entrypoint bash --name $FILENAME $PROTOCURL_IMAGE -c \"$BEFORE_TEST_BASH && ./bin/protocurl $ARGS\"" 2>"$OUT_ERR" >>"$OUT"
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
  CONVERT_TESTCASE_TO_SINGLE_TEST_INVOCATION=".[] | \"testSingleRequest \(.filename|@sh) \(.args|join(\" \")|@sh) \(.beforeTestBash // \"\"|@sh) \(.runAgainWithArg // \"\"|@sh)\""
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
