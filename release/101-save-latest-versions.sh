#!/bin/bash
set -euo pipefail

# See RELEASE.md

source release/0-get-latest-dependencies-versions.sh

OUT="${OUT:-"release/versions.txt"}"

# ignore empty lines. ignore protoCURL itself.
echo "$ALL_VERSIONS" | sed '/^$/d' | sed '/protoCURL/d' >"$OUT"

echo "Saved latest versions into $OUT."
