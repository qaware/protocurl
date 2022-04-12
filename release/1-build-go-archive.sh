#!/bin/bash
set -e

source release/source.sh

cp template.goreleaser.yaml .goreleaser.yaml
sed -i "s/__PROTO_VERSION__/$PROTO_VERSION/g" .goreleaser.yaml

set -x

goreleaser check

goreleaser release --rm-dist

# Alternate commands when testing release process locally
# goreleaser release --snapshot --rm-dist # DEV
# set -x; for file in dist/*.zip; do mv "$file" "${file/-next/}"; done # DEV

set +x

# Goreleaser adds the binary at the root in the zip. We don't want it there, hence we remove it.
for file in dist/*.zip; do
  # on windows during dev: install 7z.exe as zip.exe into bin and use d instead of -d
  zip -d "$file" protocurl || true
  zip -d "$file" protocurl.exe || true
done
