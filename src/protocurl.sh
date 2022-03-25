#!/bin/sh
set -e

# constants
VISUAL_SEPARATOR="==========================="
SEND=">>>"
RECV="<<<"

# default configuration
CURL="${CURL:-curl}"
PROTO_FILES_DIR=""
PROTO_FILE_PATH=""
REQUEST_TYPE=""
RESPONSE_TYPE=""
DISPLAY_BINARY="${DISPLAY_BINARY:-false}"
DISPLAY_RESPONSE_HEADERS="${DISPLAY_RESPONSE_HEADERS:-false}"
BINARY_DISPLAY_FORMATTING_ARGS="${BINARY_DISPLAY_FORMATTING_ARGS:--C}"
HEADER_ARGS="-H 'Content-Type: application/x-protobuf'"
ADDITIONAL_CURL_ARGS=""
VERBOSE="false"
SHOW_OUTPUT_ONLY="false"

printUsage() {
  echo "Usage: $(basename $0) [OPTIONS] -f PROTO_FILE -i REQUEST_TYPE -o RESPONSE_TYPE URL REQUEST_TXT"
}

parseArgs() {
  while getopts 'H:I:f:C:i:o:dvqh' opt; do
    case "$opt" in

    H)
      HEADER_ARGS="$HEADER_ARGS -H '$OPTARG'"
      ;;

    I)
      PROTO_FILES_DIR="$DIR"
      ;;

    C)
      ADDITIONAL_CURL_ARGS="$OPTARG"
      ;;

    f)
      PROTO_FILE_PATH="$OPTARG"
      ;;

    i)
      REQUEST_TYPE="$OPTARG"
      ;;

    o)
      RESPONSE_TYPE="$OPTARG"
      ;;

    v)
      echo "Being verbose due to -v"
      VERBOSE="true"
      DISPLAY_BINARY="true"
      DISPLAY_RESPONSE_HEADERS="true"
      ;;

    q)
      SHOW_OUTPUT_ONLY="true"
      VERBOSE="false"
      DISPLAY_BINARY="false"
      DISPLAY_RESPONSE_HEADERS="false"
      ;;

    d)
      DISPLAY_BINARY="true"
      DISPLAY_RESPONSE_HEADERS="true"
      ;;

    h)
      printUsage
      exit 0
      ;;

    :)
      printUsage
      exit 1
      ;;

    ?)
      printUsage
      exit 1
      ;;
    esac
  done
  shift "$(($OPTIND - 1))"

  # todo. perhaps make these args non-positional
  URL="$1"

  REQUEST_TXT="$2"

  PROTO_FILES_DIR="/proto"
  PROTO="$PROTO_FILES_DIR/$PROTO_FILE_PATH -I $PROTO_FILES_DIR"

  set +e
  $VERBOSE && echo "Request type: $REQUEST_TYPE"
  $VERBOSE && echo "Response type: $RESPONSE_TYPE"
  $VERBOSE && echo "Request text: $REQUEST_TXT"
  $VERBOSE && echo "Url: $URL"
  $VERBOSE && echo "Directory of proto files: $PROTO_FILES_DIR"
  $VERBOSE && echo "Path to proto file: $PROTO_FILES_DIR/$PROTO_FILE_PATH"
  $VERBOSE && echo "Using cURL Headers: $HEADER_ARGS"
  set -e
}

encodeRequestBody() {
  rm -f request.bin || true
  echo "$REQUEST_TXT" | protoc --encode "$REQUEST_TYPE" $PROTO >request.bin

  $SHOW_OUTPUT_ONLY || echo "$VISUAL_SEPARATOR Request Text   $VISUAL_SEPARATOR $SEND"
  $SHOW_OUTPUT_ONLY || cat request.bin | protoc --decode "$REQUEST_TYPE" $PROTO

  $DISPLAY_BINARY && echo "$VISUAL_SEPARATOR Request Binary $VISUAL_SEPARATOR $SEND" && hexdump "$BINARY_DISPLAY_FORMATTING_ARGS" request.bin || true
}

executeRequest() {
  rm -f response.bin || true
  rm -f response-headers.txt || true

  eval "$CURL -s \
    -X POST \
    $HEADER_ARGS \
    $ADDITIONAL_CURL_ARGS \
    --data-binary @request.bin \
    --output response.bin \
    --dump-header response-headers.txt \
    $URL"
  # The use of eval is needed here, so that HEADER_ARGS='-H "Name: MyValue"' is properly expanded into curl -H "Name: MyValue"
}

decodeResponse() {
  $DISPLAY_RESPONSE_HEADERS && echo "$VISUAL_SEPARATOR Response Headers $VISUAL_SEPARATOR $RECV" && cat response-headers.txt || true

  $DISPLAY_BINARY && echo "$VISUAL_SEPARATOR Response Binary $VISUAL_SEPARATOR $RECV" && hexdump "$BINARY_DISPLAY_FORMATTING_ARGS" response.bin || true

  $SHOW_OUTPUT_ONLY || echo "$VISUAL_SEPARATOR Response Text   $VISUAL_SEPARATOR $RECV"
  cat response.bin | protoc --decode "$RESPONSE_TYPE" $PROTO
}

parseArgs "$@"
encodeRequestBody
executeRequest
decodeResponse
