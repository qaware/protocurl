#!/bin/sh
# https://carlosbecker.com/posts/golang-completions-cobra/
set -e

rm -rf completions
mkdir completions
for sh in bash zsh fish; do
	go run src/protocurl.go completion "$sh" >"completions/protocurl.$sh"
done
