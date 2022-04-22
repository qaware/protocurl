#!/bin/bash
set -e

LATEST_VERSION=""

retrieveLatestVersion() {
  REPO="$1"
  TAG_FILTER="$2"

  GITHUB_REFS="$(curl -s \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO/git/matching-refs/tags")"

  FULL_REF_FILTER="^refs/tags/$TAG_FILTER\$"

  FILTERED_TAGS="$(echo "$GITHUB_REFS" | jq -r ".[] | select(.ref | test(\"$FULL_REF_FILTER\")) | .ref")"

  LATEST_VERSION="$(echo "$FILTERED_TAGS" | tail -n 1)" # it seems, that github lists the tags chronologically. last is latest

  if [[ "$LATEST_VERSION" == "" ]]; then
    echo "Found tags after filtering:"
    echo "$FILTERED_TAGS"
    echo "Error: Could not find latest tag for github.com/$REPO with filter $TAG_FILTER"
    echo "Result: $LATEST_VERSION"
    exit 1
  fi

  LATEST_VERSION="${LATEST_VERSION#"refs/tags/"}"
}

# retrieve version: Google Protobuf
retrieveLatestVersion "protocolbuffers/protobuf" "v3[.][0-9]+[.][0-9]+"
export PROTO_VERSION="${LATEST_VERSION#"v"}"
echo "Established Protobuf version $PROTO_VERSION"

# retrieve version: go
retrieveLatestVersion "golang/go" "go1[.][0-9]+[.][0-9]+"
GO_VERSION="${LATEST_VERSION#"go"}"
GO_VERSION="$(echo "$GO_VERSION" | sed -E "s/\.[0-9]+$//")" # remove patch version
echo "Established Go version: $GO_VERSION"

# retrieve version: goreleaser
retrieveLatestVersion "goreleaser/goreleaser" "v1[.][0-9]+[.][0-9]+"
export GORELEASER_VERSION="$LATEST_VERSION"
echo "Established Goreleaser version: $GORELEASER_VERSION"

# retrieve version: protocurl
retrieveLatestVersion "qaware/protocurl" "v[0-9]+[.][0-9]+[.][0-9]+"
export PROTOCURL_RELEASED_VVERSION="$LATEST_VERSION"
echo "Established latest released protoCURL version: $PROTOCURL_RELEASED_VVERSION"

# compute download urls
ARCH="$(uname -m | sed "s/x86_64/amd64/" | sed "s/x86_32/386/")"

export GO_DOWNLOAD_URL="https://go.dev/dl/go${GO_VERSION}.linux-$ARCH.tar.gz"
export GO_DOWNLOAD_URL_ARCH_TEMPLATE="https://go.dev/dl/go${GO_VERSION}.linux-__ARCH__.tar.gz" # used in Dockerfile

export GORELEASER_DOWNLOAD_URL="https://github.com/goreleaser/goreleaser/releases/download/${GORELEASER_VERSION}/goreleaser_${GORELEASER_VERSION#"v"}_${ARCH}.deb"
