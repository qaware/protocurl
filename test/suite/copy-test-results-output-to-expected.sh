#!/bin/bash
set -e

# Copy each <my-testcase>-out.txt to <my-testcase>-expected.txt

FILES="$(ls -a test/results/*-out.txt)"

echo "$FILES" | xargs -I + sh -c 'cp "$1" "${1%"-out.txt"}-expected.txt"; echo "${1%"-out.txt"}" ' -- +