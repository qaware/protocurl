#!/bin/bash
set -e

source release/source.sh

cp template.goreleaser.yaml .goreleaser.yaml

sed -i "s/__PROTO_VERSION__/$PROTO_VERSION/g" .goreleaser.yaml

cat .goreleaser.yaml

goreleaser release --rm-dist
# use --snapshot for testing release process