set -e

# Test suite: Starts the server and sends multiple requests against it to check the log output

WORKING_DIR="$1"

export RUN_CLIENT="docker run --rm -v $WORKING_DIR/test/proto:/proto --network host"

export SHOW_LOGS="docker logs"

export TESTS_SUCCESS="true"

source test/suite/setup.sh

normaliseOutput() {
  # normalise line endings
  sed -i 's/^M$//' "$1"

  # deletes all lines starting at a go traceback
  sed -i '/goroutine 1.*/,$d' "$1"

  # test text format is sometimes unstable and serialises to "<field>: <value>" or "<field>:  <value>" randomly
  # But this difference does not actually matter, hence we normalise this away.
  sed -i "s/:  /: /" "$1"
}
export -f normaliseOutput

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
    normaliseOutput "$EXPECTED"
    rm -f "$OUT" || true
    rm -f "$OUT_ERR" || true
    echo "######### STDOUT #########" > "$OUT"

    set +e

    if [[ "$BEFORE_TEST_BASH" == "" ]]; then
      eval "$RUN_CLIENT --name $FILENAME protocurl $ARGS" 2> "$OUT_ERR" >> "$OUT"
    else
      ARGS="$(echo "$ARGS" | sed 's/"/\\"/g' )" # escape before usage inside quoted context
      eval "$RUN_CLIENT --entrypoint bash --name $FILENAME protocurl -c \"$BEFORE_TEST_BASH && ./protocurl $ARGS\"" 2> "$OUT_ERR" >> "$OUT"
    fi
    echo "######### STDERR #########" >> "$OUT"
    cat "$OUT_ERR" >> "$OUT"
    normaliseOutput "$OUT"

    diff -I 'Date: .*' --strip-trailing-cr "$EXPECTED" "$OUT" >/dev/null

    if [[ "$?" != 0 ]]; then
      export TESTS_SUCCESS="false"
      echo "❌❌❌ FAILURE ❌❌❌ - $FILENAME"
      echo "=== Found difference between expected and actual output (ignoring date, go traceback, text format indentation) ==="
      diff -I 'Date: .*' --strip-trailing-cr "$EXPECTED" "$OUT" | sed 's/^/  /'
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