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
echo "$USAGE" >doc/generated.usage.txt

echo "Done."

# ====================================================================================
# Generate Example Commands
echo "Generate EXAMPLE.md..."

EXAMPLES_TEMPLATE="$(cat doc/template.EXAMPLES.md)"

# EXAMPLE 1 ============================
EXAMPLE_1_OUT="$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -i ..HappyDayRequest -o ..HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "includeReason: true")"

EXAMPLE_1="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host qaware/protocurl \\
   -i ..HappyDayRequest -o ..HappyDayResponse \\
   -u http://localhost:8080/happy-day/verify \\
   -d \"includeReason: true\"

$EXAMPLE_1_OUT"

escapeString "$EXAMPLE_1_OUT"
EXAMPLE_1_OUT="$ESCAPED"

escapeString "$EXAMPLE_1"
EXAMPLE_1="$ESCAPED"

# EXAMPLE 2 ============================
EXAMPLE_2="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host qaware/protocurl \\
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \\
  -u http://localhost:8080/happy-day/verify -d \"\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  -u http://localhost:8080/happy-day/verify -d "")"

escapeString "$EXAMPLE_2"
EXAMPLE_2="$ESCAPED"

# EXAMPLE_3 ============================
EXAMPLE_3="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host qaware/protocurl \\
  -i ..HappyDayRequest -o ..HappyDayResponse \\
  -u http://localhost:8080/happy-day/verify \\
  -d \"date: { seconds: 1648044939}\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -i ..HappyDayRequest -o ..HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "date: { seconds: 1648044939}")"

escapeString "$EXAMPLE_3"
EXAMPLE_3="$ESCAPED"

# EXAMPLE_JSON ============================
EXAMPLE_JSON="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host qaware/protocurl \\
  -i ..HappyDayRequest -o ..HappyDayResponse \\
  -u http://localhost:8080/happy-day/verify \\
  -d \"{ \\\"date\\\": \\\"2022-03-23T14:15:39Z\\\" }\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -i ..HappyDayRequest -o ..HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "{ \"date\": \"2022-03-23T14:15:39Z\" }")"

escapeString "$EXAMPLE_JSON"
EXAMPLE_JSON="$ESCAPED"

# EXAMPLE_JSON ============================
EXAMPLE_JSON_PRETTY="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host qaware/protocurl \\
  -i ..HappyDayRequest -o ..HappyDayResponse \\
  -u http://localhost:8080/happy-day/verify --out=json:pretty \\
  -d \"{ \\\"date\\\": \\\"2022-03-23T14:15:39Z\\\" }\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -i ..HappyDayRequest -o ..HappyDayResponse \
  -u http://localhost:8080/happy-day/verify --out=json:pretty \
  -d "{ \"date\": \"2022-03-23T14:15:39Z\" }")"

escapeString "$EXAMPLE_JSON_PRETTY"
EXAMPLE_JSON_PRETTY="$ESCAPED"

# EXAMPLE OUTPUT ONLY =============================
EXAMPLE_OUTPUT_ONLY="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host qaware/protocurl \\
   -q -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \\
   -u http://localhost:8080/happy-day/verify \\
   -d \"includeReason: true\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -q -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "includeReason: true")"

escapeString "$EXAMPLE_OUTPUT_ONLY"
EXAMPLE_OUTPUT_ONLY="$ESCAPED"

# EXAMPLE OUTPUT ONLY WITH ERROR =============================
EXAMPLE_OUTPUT_ONLY_WITH_ERR_1="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host qaware/protocurl \\
   -q -i ..HappyDayRequest -o ..HappyDayResponse \\
   -u http://localhost:8080/does-not-exist \\
   -d \"\""

escapeString "$EXAMPLE_OUTPUT_ONLY_WITH_ERR_1"
EXAMPLE_OUTPUT_ONLY_WITH_ERR_1="$ESCAPED"

docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -q -i ..HappyDayRequest -o ..HappyDayResponse \
  -u http://localhost:8080/does-not-exist \
  -d "" 2>.EXAMPLE_OUTPUT_ONLY_WITH_ERR_2.out || true

normaliseOutput .EXAMPLE_OUTPUT_ONLY_WITH_ERR_2.out
# we need to normalise the gorouting trace away, as otherwise it would remove everything after that in the final normalisation
EXAMPLE_OUTPUT_ONLY_WITH_ERR_2="$(cat .EXAMPLE_OUTPUT_ONLY_WITH_ERR_2.out)"
rm -rf .EXAMPLE_OUTPUT_ONLY_WITH_ERR_2.out
escapeString "$EXAMPLE_OUTPUT_ONLY_WITH_ERR_2"
EXAMPLE_OUTPUT_ONLY_WITH_ERR_2="${ESCAPED}"

# EXAMPLE_4 ============================
EXAMPLE_4="\$ docker run -v \"\$PWD/test/proto:/proto\" --network host qaware/protocurl \\
  -v -i ..HappyDayRequest -o ..HappyDayResponse \\
  -u http://localhost:8080/happy-day/verify \\
  -d \"date: { seconds: 1648044939}\"

$(docker run -v "$WORKING_DIR/test/proto:/proto" --network host protocurl \
  -v -i ..HappyDayRequest -o ..HappyDayResponse \
  -u http://localhost:8080/happy-day/verify \
  -d "date: { seconds: 1648044939}")"

escapeString "$EXAMPLE_4"
EXAMPLE_4="$ESCAPED"

# replacements ============================
echo "$EXAMPLES_TEMPLATE" |
  sed "s%___EXAMPLE_1___%$EXAMPLE_1%" |
  sed "s%___EXAMPLE_2___%$EXAMPLE_2%" |
  sed "s%___EXAMPLE_3___%$EXAMPLE_3%" |
  sed "s%___EXAMPLE_JSON___%$EXAMPLE_JSON%" |
  sed "s%___EXAMPLE_JSON_PRETTY___%$EXAMPLE_JSON_PRETTY%" |
  sed "s%___EXAMPLE_OUTPUT_ONLY___%$EXAMPLE_OUTPUT_ONLY%" |
  sed "s%___EXAMPLE_OUTPUT_ONLY_WITH_ERR_1___%$EXAMPLE_OUTPUT_ONLY_WITH_ERR_1%" |
  sed "s%___EXAMPLE_OUTPUT_ONLY_WITH_ERR_2___%$EXAMPLE_OUTPUT_ONLY_WITH_ERR_2%" |
  sed "s%___EXAMPLE_4___%$EXAMPLE_4%" >EXAMPLES.md

normaliseOutput EXAMPLES.md

echo "Done."

# ====================================================================================
# Generate Readme
echo "Generating README.md..."

README_TEMPLATE="$(cat doc/template.README.md)"

# replacements ============================
echo "$README_TEMPLATE" |
  sed "s%___EXAMPLE_1_OUT___%$EXAMPLE_1_OUT%" >README.md

normaliseOutput README.md

echo "Done."

# ====================================================================================

tearDown
