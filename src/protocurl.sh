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
URL=""
DISPLAY_BINARY="${DISPLAY_BINARY:-false}"
DISPLAY_RESPONSE_HEADERS="${DISPLAY_RESPONSE_HEADERS:-false}"
BINARY_DISPLAY_FORMATTING_ARGS="${BINARY_DISPLAY_FORMATTING_ARGS:--C}"
HEADER_ARGS="-H 'Content-Type: application/x-protobuf'"
ADDITIONAL_CURL_ARGS=""
VERBOSE="false"
SHOW_OUTPUT_ONLY="false"

# =================================================================== USAGE

printUsage() {
  echo "  Usage: protocurl.sh [OPTIONS] -f PROTO_FILE -i REQUEST_TYPE -o RESPONSE_TYPE -u URL REQUEST_TXT"
  echo ""
  echo "  Send and receive HTTP/1.1 requests on a protobuf REST endpoint and interact with it using human-readable text formats."
  echo ""
  echo "  EXAMPLE:"
  echo "      protocurl.sh -I my-protos -f messages.proto -i package.path.Req -o package.path.Resp -u http://foo.com/api \"myField: true, otherField: 1337\""
  echo ""
  echo "  POSITIONAL ARGUMENTS:"
  echo "      1. REQUEST_TXT      The protobuf request in the text format. For an description of the format, see https://github.com/qaware/protocurl."
  echo ""
  echo "  OPTIONS:"
  echo "      -I PROTO_DIRECTORY  Uses the specified directory to find the proto-file. This is always '/proto' in docker."
  echo "      -f PROTO_FILE       Uses the specified file path to find the protobuf definitions within PROTO_DIRECTORY (relative file path)."
  echo "      -i REQUEST_TYPE     Package path of the protobuf request type. E.g. mypackage.MyRequest"
  echo "      -o RESPONSE_TYPE    Package path of the protobuf response type. E.g. mypackage.MyResponse"
  echo "      -u URL              The url to send the request to"
  echo "      -H HEADER           Adds the header to the invocation of cURL. E.g. -H 'MyHeader: FooBar'"
  echo "      -C CURL_ARGS        Additional cURL args which will be passed on to cURL during request invocation."
  echo "      -v                  Enables verbose output. Also activates -d."
  echo "      -d                  Displays the binary request and response as well as the non-binary response headers."
  echo "      -q                  This feature is UNTESTED: Suppresses the display of the request and only displays the text output. Deactivates -v and -d."
  echo "      -h                  Prints this help."
  echo ""
}



# =================================================================== PARSE ARGS

parseArgs() {
  while getopts 'I:f:i:o:u:H:C:vdqh' opt; do
    case "$opt" in
    I)
      PROTO_FILES_DIR="$DIR" ;;
    f)
      PROTO_FILE_PATH="$OPTARG" ;;
    i)
      REQUEST_TYPE="$OPTARG" ;;
    o)
      RESPONSE_TYPE="$OPTARG" ;;
    u)
      URL="$OPTARG" ;;
    H)
      HEADER_ARGS="$HEADER_ARGS -H '$OPTARG'" ;;
    C)
      ADDITIONAL_CURL_ARGS="$OPTARG" ;;
    v)
      echo "Being verbose due to -v"
      VERBOSE="true"
      DISPLAY_BINARY="true"
      DISPLAY_RESPONSE_HEADERS="true" ;;
    d)
      DISPLAY_BINARY="true"
      DISPLAY_RESPONSE_HEADERS="true" ;;
    q)
      SHOW_OUTPUT_ONLY="true"
      VERBOSE="false"
      DISPLAY_BINARY="false"
      DISPLAY_RESPONSE_HEADERS="false" ;;
    h)
      printUsage
      exit 0 ;;
    :)
      printUsage
      exit 1 ;;
    ?)
      printUsage
      exit 1 ;;
    esac
  done
  shift "$(($OPTIND - 1))"

  if [ $# -eq 0 ]; then
    printUsage
    exit 1
  fi

  REQUEST_TXT="$1"

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



# =================================================================== PROTOCURL MAIN DEFINITIONS

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


# =================================================================== PROTOCURL EXECUTION

parseArgs "$@"
encodeRequestBody
executeRequest
decodeResponse
