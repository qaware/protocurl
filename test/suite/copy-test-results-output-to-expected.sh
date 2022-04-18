#!/bin/bash
set -e

source test/suite/setup.sh

# Copy each <my-testcase>-out.txt to <my-testcase>-expected.txt

FILES="$(ls -a test/results/*-out.txt)"

copyIfDiff() {
  meaningfulDiff "$1" "${1%"-out.txt"}-expected.txt" >/dev/null
  if [[ "$?" == "0" ]]; then
    echo "✅ ${1%"-out.txt"}"
  else
    cp "$1" "${1%"-out.txt"}-expected.txt"
    echo "▶️  ${1%"-out.txt"}"
  fi
}
export -f copyIfDiff

echo "$FILES" | xargs -I + bash -c 'copyIfDiff "$@"' _ +
