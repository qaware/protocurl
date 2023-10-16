#!/bin/bash
set -euo pipefail

source ./release/0-get-latest-dependencies-versions.sh

FILES_EXIST="true"
ls release/tmp/protoc-$PROTO_VERSION-*.zip > /dev/null 2>&1 || FILES_EXIST="false"

if [[ "$FILES_EXIST" == "true" ]]; then
  echo "Found protoc binaries for $PROTO_VERSION."
else
  echo "No protoc binaries for $PROTO_VERSION found. Downloading..."
  ./release/10.1-get-protoc-binaries.sh
fi
