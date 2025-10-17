#!/bin/bash
set -euo pipefail

LATEST_VERSION=""

HEADERS_FILE="release/.cache/headers.txt"

# track all versions, so that we can detect any changes.
export ALL_VERSIONS=""

registerVersion() {
  NAME="$1"
  VERSION_VAR="$2"
  VERSION_VALUE="${!VERSION_VAR}"

  ALL_VERSIONS="$ALL_VERSIONS"$'\n'"$NAME $VERSION_VALUE"

  echo "Established $NAME version $VERSION_VALUE"
}

retrieveLatestVersion() {
  TYPE="$1" # tag or release
  REPO="$2"
  TAG_FILTER="$3"
  VERSION_PREFIX="$4"

  FILE_FRIENDLY_NAME="$(echo "$REPO" | sed 's#/#.#g')"

  CACHE_FILE="release/.cache/$FILE_FRIENDLY_NAME.cache.json"
  ETAG_FILE="release/.cache/$FILE_FRIENDLY_NAME.etag"
  ETAG="$(cat "$ETAG_FILE" 2>/dev/null || echo '')"

  # Actually, we should only be getting the first 100 tags.
  # However, currently github returns all tags.
  # See issue: https://github.com/github/docs/issues/3863
  ENDPOINT="git/matching-refs/tags?per_page=100"
  RESPONSE_FILTER="^refs/tags/$TAG_FILTER\$"
  PATH_TO_TAG=".ref"

  AUTH_ARGS=()
  if [[ -v GITHUB_TOKEN ]]; then
    AUTH_ARGS+=("-H" "Authorization: $GITHUB_TOKEN")
  fi

  GITHUB_RESPONSE="$(curl --silent --show-error --fail-with-body \
    -D "$HEADERS_FILE" \
    --etag-save "$ETAG_FILE" \
    -H "If-None-Match: $ETAG" \
    -H "Accept: application/vnd.github.v3+json" \
    "${AUTH_ARGS[@]}" \
    "https://api.github.com/repos/$REPO/$ENDPOINT")"

  STATUS_CODE_LINE="$(cat "$HEADERS_FILE" | head -n 1)"

  if [[ "$STATUS_CODE_LINE" == *" 200"* ]]; then
    echo "Populating cache..."
    echo "$GITHUB_RESPONSE" >"$CACHE_FILE"
  fi

  if [[ "$STATUS_CODE_LINE" == *" 304"* ]]; then
    echo "Using cache..."
    GITHUB_RESPONSE="$(cat "$CACHE_FILE")"
  fi

  FILTERED_TAGS="$(echo "$GITHUB_RESPONSE" | jq -r ".[] | select($PATH_TO_TAG | test(\"$RESPONSE_FILTER\")) | $PATH_TO_TAG")"

  LATEST_VERSION="$(
    echo -n "$FILTERED_TAGS" \
    | jq -r -R -s "split(\"\n\") | sort_by(split(\"$VERSION_PREFIX\")[1] | split(\".\") | map(tonumber)) | last"
  )"

  if [[ ! -v LATEST_VERSION ]]; then
    echo "Found tags after filtering:"
    echo "$FILTERED_TAGS"
    echo "Error: Could not find latest $TYPE for github.com/$REPO with filter $TAG_FILTER"
    echo "Result: $LATEST_VERSION"
    exit 1
  fi

  LATEST_VERSION="${LATEST_VERSION#"refs/tags/"}"
}

# retrieve version: Google Protobuf
retrieveLatestVersion "tag" "protocolbuffers/protobuf" "v[0-9]+[.][0-9]+" "v"
export PROTO_VERSION="${LATEST_VERSION#"v"}"
registerVersion "Protobuf" "PROTO_VERSION"

# retrieve version: go
retrieveLatestVersion "tag" "golang/go" "go1[.][0-9]+[.][0-9]+" "go"
GO_VERSION="${LATEST_VERSION#"go"}"
# GO_VERSION="$(echo "$GO_VERSION" | sed -E "s/\.[0-9]+$//")" # remove patch version
registerVersion "go" "GO_VERSION"

# retrieve version: goreleaser
retrieveLatestVersion "tag" "goreleaser/goreleaser" "v1[.][0-9]+[.][0-9]+" "v"
export GORELEASER_VERSION="$LATEST_VERSION"
registerVersion "Goreleaser" "GORELEASER_VERSION"

# retrieve version: protocurl
retrieveLatestVersion "tag" "qaware/protocurl" "v[0-9]+[.][0-9]+[.][0-9]+" "v"
export PROTOCURL_RELEASED_VVERSION="$LATEST_VERSION"
registerVersion "Latest released protoCURL" "PROTOCURL_RELEASED_VVERSION"

# compute download urls
ARCH="$(uname -m | sed "s/x86_64/amd64/" | sed "s/x86_32/386/")"

export GO_DOWNLOAD_URL="https://go.dev/dl/go${GO_VERSION}.linux-$ARCH.tar.gz"
export GO_DOWNLOAD_URL_ARCH_TEMPLATE="https://go.dev/dl/go${GO_VERSION}.linux-__ARCH__.tar.gz" # used in Dockerfile

export GORELEASER_DOWNLOAD_URL="https://github.com/goreleaser/goreleaser/releases/download/${GORELEASER_VERSION}/goreleaser_${GORELEASER_VERSION#"v"}_${ARCH}.deb"
