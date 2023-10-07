#!/bin/bash

set -euo pipefail

source test/suite/setup.sh

setup

docker rm -f protocurl-test-runner >/dev/null 2>&1 || true # remove any running test-runner

docker run --rm --name protocurl-test-runner \
  -v "$PWD/test/proto:/proto" \
  --network host \
  -v "$PWD:/wd" \
  --entrypoint bash \
  "$PROTOCURL_IMAGE" \
  -c "cd /wd && git config --global --add safe.directory /wd && ./test/suite/test.sh"

tearDown
