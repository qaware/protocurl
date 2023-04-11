#!/bin/bash
set -e

# Concatenate the dev dockerfile and the final release dockerfile to get the combined one
cat dev/builder.local.Dockerfile <(echo "# ==================") release/final.Dockerfile >dev/generated.local.Dockerfile
