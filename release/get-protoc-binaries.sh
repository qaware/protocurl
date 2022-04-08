#!/bin/bash
set -e

PROTO_VERSION="3.20.0"

VARIATIONS=(
  "linux-aarch_64"
  "linux-x86_32"
  "linux-x86_64"
  "osx-aarch_64"
  "osx-x86_64"
  "win32"
  "win64"
)

rm -rf release/tmp || true
mkdir -p release/tmp

for PLAT_ARCH in "${VARIATIONS[@]}"; do
  URL="https://github.com/protocolbuffers/protobuf/releases/download/v$PROTO_VERSION/protoc-$PROTO_VERSION-$PLAT_ARCH.zip"

  echo "Downloading $URL ..."
  curl -s -L -o "release/tmp/protoc-$PROTO_VERSION-$PLAT_ARCH.zip" "$URL"

  # Normalise platform name for integration into Goreleaser
  NORM_PLAT_ARCH="$(echo "$PLAT_ARCH" | sed "s/win32/win-x86_32/" | sed "s/win64/win-x86_64/")"

  echo "Extracting $PROTO_VERSION-$PLAT_ARCH to $PROTO_VERSION-$NORM_PLAT_ARCH"
  unzip -q -d "release/tmp/protoc-$PROTO_VERSION-$NORM_PLAT_ARCH" "release/tmp/protoc-$PROTO_VERSION-$PLAT_ARCH.zip"
done

echo "Done."
