#!/bin/bash
set -e

source ./release/get-latest-dependencies-versions.sh

# should be one of 386, amd64 and arm64
export BUILD_ARCH="$(uname -m | sed "s/x86_64/amd64/" | sed "s/x86_32/386/" | sed "s/aarch_64/arm64/")"

if [[ "$VVERSION" == "" ]]; then
  export VVERSION="$(git tag --points-at HEAD --sort -version:refname | head -n 1)"
fi

# any version: e.g. v1.2.3, v23.45.67-dev
if [[ "$VVERSION" =~ v.*\..*\..* ]]; then

  # any snapshot version with a -
  # e.g. v23.45.67-dev but not v1.2.3
  if  [[ "$VVERSION" =~ v.*\..*\..*[-].* ]]; then
    export SNAPSHOT="true"
  else
    export SNAPSHOT="false"
  fi

  export VERSION="${VVERSION#"v"}"
  echo "Using VERSION=$VERSION, VVERSION=$VVERSION, SNAPSHOT=$SNAPSHOT, BUILD_ARCH=$BUILD_ARCH, PROTO_VERSION=$PROTO_VERSION"
else
  echo "Closest git tag is not a version tag: $VVERSION"
  echo "Could not extract current version from git tags. Please tag accordingly. Or provide one manually"
  exit 1
fi
