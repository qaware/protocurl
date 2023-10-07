#!/bin/bash
set -euo pipefail
set -x

# Installs Go inside a GitHub action VM / Docker container environment

# avoid anyone accidentally running this on their development computer
if [[ "$2" == "this-is-not-my-development-computer" ]]; then

  URL="$1"

  echo "Installing go from $URL"

  curl -s -L -o go.tar.gz "$URL"

  rm -rf /usr/local/go

  tar -C /usr/local -xzf go.tar.gz

  ln -s /usr/local/go/bin/go /usr/local/bin/go

  echo "Done."

else
  echo "This should only be run inside a docker container / Dockerfile build process as it will overwrite your exisitng global go installation."
  exit 1
fi
