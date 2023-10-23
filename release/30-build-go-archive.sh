#!/bin/bash
set -euo pipefail

source release/source.sh

set -x

goreleaser check

echo "Using GORELEASER_CURRENT_TAG=$GORELEASER_CURRENT_TAG, GORELEASER_PREVIOUS_TAG=$GORELEASER_PREVIOUS_TAG"

GORELEASER_ARGS=""
if [[ "$SNAPSHOT" == "true" ]]; then
  GORELEASER_ARGS="--skip=announce"
fi

goreleaser release --clean $GORELEASER_ARGS

# Alternate commands when testing release process locally
# goreleaser release --snapshot --clean # DEV
# set -x; for file in dist/*.zip; do mv "$file" "${file/-next/}"; done # DEV

set +x
