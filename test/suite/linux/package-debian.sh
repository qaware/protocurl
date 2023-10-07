#!/bin/bash
set -euo pipefail

setup() {
  apt-get update -q
  apt-get install -q -y curl gnupg apt-transport-https
  curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
  sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-bullseye-prod bullseye main" > /etc/apt/sources.list.d/microsoft.list'
  apt-get update -q && apt-get install -y powershell
}
export -f setup

install() {
  URL="$1"
  curl -sL -o protocurl.deb "$URL"
  ls /home
  dpkg --install protocurl.deb
}
export -f install

remove() {
  dpkg --remove protocurl
}
export -f remove
