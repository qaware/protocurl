#!/bin/bash
set -e

source ./release/get-latest-dependencies-versions.sh

# should be one of 386, amd64 and arm64
export BUILD_ARCH="$(uname -m | sed "s/x86_64/amd64/" | sed "s/x86_32/386/" | sed "s/aarch_64/arm64/")"

export VVERSION="$(git for-each-ref --sort='-committerdate' --count 1 --format '%(refname:short)' refs/tags)"

if [[ "$VVERSION" =~ v.*\..*\..* ]]; then
  export VERSION="${VVERSION#"v"}"
  echo "Using VERSION=$VERSION, VVERSION=$VVERSION, BUILD_ARCH=$BUILD_ARCH, PROTO_VERSION=$PROTO_VERSION"
else
  echo "Closest git tag is not a version tag: $VVERSION"
  echo "Could not extract current version from git tags. Please tag accordingly. Or provide one manually"
  exit 1
fi
