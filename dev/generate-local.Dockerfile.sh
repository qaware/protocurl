#!/bin/bash
set -e
cat dev/builder.local.Dockerfile release/final.Dockerfile >dev/generated.local.Dockerfile
