#!/bin/bash
set -euo pipefail

SAVED="release/versions.txt"
NEW="release/new.versions.txt"

echo "Checking $SAVED against latest versions..."

# Ths scripts checks the latest versions of the dependencies against what is checked in at versions.log.
# See RELEASE.md

OUT="$NEW" ./release/101-save-latest-versions.sh

if diff "$SAVED" "$NEW"; then
  echo "✅ No new dependency versions."
else
  echo "❗❗ New dependency versions found ❗❗"
  # diff is automatically printed in the if statement
  echo "Please do the following:
  1. Run ./release/101-save-latest-versions.sh
  2. Commit new versions
  3. Create a new release"
  exit 1
fi
