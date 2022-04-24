#!/bin/bash
set -e
cat release/builder.Dockerfile release/final.Dockerfile >release/generated.Dockerfile
