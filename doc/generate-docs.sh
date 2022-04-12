#!/bin/bash
set -e

WORKING_DIR="$1"

source test/suite/setup.sh

ESCAPED="failed to substitute"
escapeString() {
  ESCAPED="$(printf '%q' "$1")"
  ESCAPED="${ESCAPED#"\$'"}"
  ESCAPED="${ESCAPED%"'"}"
  ESCAPED="${ESCAPED//&/\\&}" # escape ampersand for sed
}

setup

# ====================================================================================
# Generate Usage
echo "Generating Usage..."

USAGE="$(docker run --rm protocurl -h)"
echo "$USAGE" > doc/generated.usage.txt

echo "Done."

# ====================================================================================
# Generate Example Commands
echo "Generate EXAMPLE.md..."

EXAMPLES_TEMPLATE="$(cat doc/template.EXAMPLES.md)"


# EXAMPLE 1 ============================
EXAMPLE_1="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host protocurl \\
   -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \\
   -u http://localhost:8080/happy-day/verify \\
   -d \"includeReason: true\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "includeReason: true")"

escapeString "$EXAMPLE_1"
EXAMPLE_1="$ESCAPED"


# EXAMPLE 2 ============================
EXAMPLE_2="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host protocurl \\
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \\
  -u http://localhost:8080/happy-day/verify -d \"\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  -u http://localhost:8080/happy-day/verify -d "")"

escapeString "$EXAMPLE_2"
EXAMPLE_2="$ESCAPED"


# EXAMPLE_3 ============================
EXAMPLE_3="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host protocurl \\
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \\
  -u http://localhost:8080/happy-day/verify \\
  -d \"date: { seconds: 1648044939}\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "date: { seconds: 1648044939}")"

escapeString "$EXAMPLE_3"
EXAMPLE_3="$ESCAPED"


# EXAMPLE_4 ============================
EXAMPLE_4="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host protocurl \\
  -v -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \\
  -u http://localhost:8080/happy-day/verify \\
  -d \"date: { seconds: 1648044939}\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -v -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "date: { seconds: 1648044939}")"

escapeString "$EXAMPLE_4"
EXAMPLE_4="$ESCAPED"


# replacements ============================
echo "$EXAMPLES_TEMPLATE" \
  | sed "s%___EXAMPLE_1___%$EXAMPLE_1%" \
  | sed "s%___EXAMPLE_2___%$EXAMPLE_2%" \
  | sed "s%___EXAMPLE_3___%$EXAMPLE_3%" \
  | sed "s%___EXAMPLE_4___%$EXAMPLE_4%" > EXAMPLES.md

normaliseOutput EXAMPLES.md

echo "Done."

# ====================================================================================

tearDown
