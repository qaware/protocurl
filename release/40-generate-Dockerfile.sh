#!/bin/bash
set -e
cat release/builder.Dockerfile <(echo "# ==================") release/final.Dockerfile >release/generated.Dockerfile
