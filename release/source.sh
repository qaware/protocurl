#!/usr/bin/env bash
set -euo pipefail

# PRECONDITION: git fetch origin --tags

source ./release/10-ensure-protoc-binaries-exist.sh

# should be one of 386, amd64 and arm64
BUILD_ARCH="$(uname -m | sed "s/x86_64/amd64/" | sed "s/x86_32/386/" | sed "s/aarch_64/arm64/")"
export BUILD_ARCH

# ensure, that 1.2.3-rc < 1.2.3, since the opposite is the default
git config versionsort.suffix -
# See: https://github.com/git/git/blob/master/Documentation/config/versionsort.txt

if [[ ! -v VVERSION ]]; then

  GIT_TAG="$(git tag --points-at HEAD --sort -version:refname | head -n 1)"
  if [[ "$GIT_TAG" != "" ]]; then
    export VVERSION="$GIT_TAG"
  else
    LATEST_TAG="$(git for-each-ref --sort='-version:refname' --count 1 --format '%(refname:short)' refs/tags)"
    export VVERSION="$LATEST_TAG-dev"
  fi
fi

# any version: e.g. v1.2.3, v23.45.67-dev
if [[ "$VVERSION" =~ v.*\..*\..* ]]; then

  # any snapshot version with a -
  # e.g. v23.45.67-dev but not v1.2.3
  if [[ "$VVERSION" =~ v.*\..*\..*[-].* ]]; then
    export SNAPSHOT="true"
  else
    export SNAPSHOT="false"
  fi

  export VERSION="${VVERSION#"v"}"
  echo "Variables: VERSION=$VERSION, VVERSION=$VVERSION, SNAPSHOT=$SNAPSHOT, BUILD_ARCH=$BUILD_ARCH, PROTO_VERSION=$PROTO_VERSION"
else
  echo "Closest git tag is not a version tag: $VVERSION"
  echo "Could not extract current version from git tags. Please tag accordingly. Or provide one manually"
  exit 1
fi
