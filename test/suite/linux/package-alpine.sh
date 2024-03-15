#!/usr/bin/env bash
set -euo pipefail
set -x

setup() {
  # Install powershell + curl + gcompat

  apk add --no-cache curl gcompat \
    ca-certificates \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl3 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs

  apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust
  # todo. auto-updating url?
  curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/powershell-7.4.1-linux-musl-x64.tar.gz -o /tmp/powershell.tar.gz
  mkdir -p /opt/microsoft/powershell/7
  tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
  chmod +x /opt/microsoft/powershell/7/pwsh
  ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
}
export -f setup

install() {
  URL="$1"
  curl -sL -o protocurl.apk "$URL"
  ls /home
  apk add --allow-untrusted protocurl.apk
}
export -f install

remove() {
  apk del protocurl
}
export -f remove
