#!/bin/bash
set -e

source release/source.sh

# Necessary for local development
# docker buildx rm protocurl-builder || true
# docker buildx create --use --name protocurl-builder

docker buildx build \
  --platform linux/amd64,linux/i386,linux/arm64 \
  --build-arg VERSION=$VERSION \
  -t qaware/protocurl:$VERSION -f release/Dockerfile \
  --push .
