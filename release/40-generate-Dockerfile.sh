#!/usr/bin/env bash
set -euo pipefail
cat release/builder.Dockerfile <(echo "# ==================") release/final.Dockerfile >release/generated.Dockerfile
