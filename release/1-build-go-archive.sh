#!/bin/bash
set -e

source release/source.sh

cp template.goreleaser.yaml .goreleaser.yaml
sed -i "s/__PROTO_VERSION__/$PROTO_VERSION/g" .goreleaser.yaml

goreleaser release --rm-dist

# Alternate commands when testing release process locally
# goreleaser release --rm-dist # DEV
# set -x; for file in dist/*.zip; do mv "$file" "${file/-next/}"; done # DEV