#!/bin/bash
set -e

# single point of configuration for bundled proto version
export PROTO_VERSION="3.20.0"

# should be one of 386, amd64 and arm64
export BUILD_ARCH="$(uname -m | sed "s/x86_64/amd64/" | sed "s/x86_32/386/" | sed "s/aarch_64/arm64/")"

export VVERSION="$(git describe --tags --abbrev=0)"

if [[ "$VVERSION" =~ v.*\..*\..* ]]; then
  export VERSION="${VVERSION#"v"}"
  echo "Using VERSION=$VERSION, VVERSION=$VVERSION, BUILD_ARCH=$BUILD_ARCH, PROTO_VERSION=$PROTO_VERSION"
else
  echo "Closest git tag is not a version tag: $VVERSION"
  echo "Could not extract current version from git tags. Please tag accordingly."
  exit 1
fi
