#!/bin/bash
set -e
cat dev/builder.local.Dockerfile release/final.Dockerfile dev/final.Dockerfile.extensions >dev/generated.local.Dockerfile
