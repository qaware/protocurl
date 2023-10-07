#!/bin/bash
set -euo pipefail

# should be run inside ./test folder within a container to test packaged linux releases

OS_NAME="$1"
EXT="$2"
URL_NO_EXT="$3"

source "./test/suite/linux/package-${OS_NAME}.sh"

setup

install "$URL_NO_EXT$EXT"

pwsh test/suite/native-tests.ps1 "/opt/protocurl" "" "isNotLocalDirTests"

# Overriding installation does not break
install "$URL"

pwsh test/suite/native-tests.ps1 "/opt/protocurl" "" "isNotLocalDirTests"

remove

[[ "$(which protocurl)" == "" ]]
