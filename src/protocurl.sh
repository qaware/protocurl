#!/bin/sh

# constants
VISUAL_SEPARATOR="==========================="
SEND=">>>"
RECV="<<<"

# default configuration
CURL="${CURL:-curl}"
PROTO_FILES_DIR=""
PROTO_FILE_PATH=""
DISPLAY_BINARY="${DISPLAY_BINARY:-false}"
DISPLAY_RESPONSE_HEADERS="${DISPLAY_RESPONSE_HEADERS:-false}"
BINARY_DISPLAY_FORMATTING_ARGS="${BINARY_DISPLAY_FORMATTING_ARGS:--C}"
HEADER_ARGS="-H 'Content-Type: application/x-protobuf'"
VERBOSE="false"
SHOW_OUTPUT_ONLY="false"

# todo. explain these env-args as well
# todo. extend -d to also show all headers etc.

printUsage() {
  echo "Usage: $(basename $0) [OPTIONS] REQUEST_TYPE RESPONSE_TYPE URL REQUEST_TXT"
}

parseArgs() {
  while getopts 'H:I:f:dvqh' opt; do
    case "$opt" in

    H)
      HEADER_ARGS="$HEADER_ARGS -H '$OPTARG'"
      ;;

    I)
      PROTO_FILES_DIR="$DIR"
      ;;

    f)
      PROTO_FILE_PATH="$OPTARG"
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

  REQUEST_TYPE="$1"
  RESPONSE_TYPE="$2"
  URL="$3"

  REQUEST_TXT="$4"
  # Remove leading and trailing ". todo. remove this and try again
  REQUEST_TXT="${REQUEST_TXT#\"}"
  REQUEST_TXT="${REQUEST_TXT%\"}"
  # TODO. detect json or text format based on first non-whitespace character. it should be { for JSON.

  PROTO_FILES_DIR="/proto"
  PROTO="$PROTO_FILES_DIR/$PROTO_FILE_PATH -I $PROTO_FILES_DIR"

  $VERBOSE && echo "Request type: $REQUEST_TYPE"
  $VERBOSE && echo "Response type: $RESPONSE_TYPE"
  $VERBOSE && echo "Request text: $REQUEST_TXT"
  $VERBOSE && echo "Url: $URL"
  $VERBOSE && echo "Directory of proto files: $PROTO_FILES_DIR"
  $VERBOSE && echo "Path to proto file: $PROTO_FILES_DIR/$PROTO_FILE_PATH"
  $VERBOSE && echo "Using cURL Headers: $HEADER_ARGS"
}

encodeRequestBody() {
  rm -f request.bin || true
  echo "$REQUEST_TXT" | protoc --encode "$REQUEST_TYPE" $PROTO >request.bin

  $SHOW_OUTPUT_ONLY || echo "$VISUAL_SEPARATOR Request Text   $VISUAL_SEPARATOR $SEND"
  $SHOW_OUTPUT_ONLY || cat request.bin | protoc --decode "$REQUEST_TYPE" $PROTO

  $DISPLAY_BINARY && echo "$VISUAL_SEPARATOR Request Binary $VISUAL_SEPARATOR $SEND" && hexdump "$BINARY_DISPLAY_FORMATTING_ARGS" request.bin
}

executeRequest() {
  rm -f response.bin || true
  rm -f response-headers.txt || true

  eval "$CURL -s \
    -X POST \
    $HEADER_ARGS \
    --data-binary @request.bin \
    --output response.bin \
    --dump-header response-headers.txt \
    $URL"
  # The use of eval is needed here, so that HEADER_ARGS='-H "Name: MyValue"' is properly expanded into curl -H "Name: MyValue"

  # TODO. handle response failure!
  # Enable one to use a different thing based on the HTTP status code?
}

decodeResponse() {
  $DISPLAY_RESPONSE_HEADERS && echo "$VISUAL_SEPARATOR Response Headers $VISUAL_SEPARATOR $RECV" && cat response-headers.txt

  $DISPLAY_BINARY && echo "$VISUAL_SEPARATOR Response Binary $VISUAL_SEPARATOR $RECV" && hexdump "$BINARY_DISPLAY_FORMATTING_ARGS" response.bin

  $SHOW_OUTPUT_ONLY || echo "$VISUAL_SEPARATOR Response Text   $VISUAL_SEPARATOR $RECV"
  cat response.bin | protoc --decode "$RESPONSE_TYPE" $PROTO
}

parseArgs "$@"
encodeRequestBody
executeRequest
decodeResponse
