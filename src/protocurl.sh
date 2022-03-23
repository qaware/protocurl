#!/bin/sh
# ========== static constants

VISUAL_SEPARATOR="==========================="
SEND=">>>"
RECV="<<<"

# ========= configuration

CURL="${CURL:-curl}"

DISPLAY_BINARY="${DISPLAY_BINARY:-false}"
DISPLAY_RESPONSE_HEADERS="${DISPLAY_RESPONSE_HEADERS:-false}"
BINARY_FORMAT_ARGS="${BINARY_FORMAT_ARGS:--C}"

PROTO_FILES_DIR="$1"
PROTO="$PROTO_FILES_DIR/$PROTO_FILE_PATH -I $PROTO_FILES_DIR"

# ========== request body

echo "$REQUEST_TXT" | protoc --encode "$REQUEST_TYPE" $PROTO > request.bin

echo "$VISUAL_SEPARATOR Request Text   $VISUAL_SEPARATOR $SEND"
cat request.bin | protoc --decode "$REQUEST_TYPE" $PROTO

# shellcheck disable=SC2086
$DISPLAY_BINARY && echo "$VISUAL_SEPARATOR Request Binary $VISUAL_SEPARATOR $SEND" && hexdump $BINARY_FORMAT_ARGS request.bin
CONTENT_TYPE_HEADER="${CONTENT_TYPE_HEADER:-application/x-protobuf}"

# =========== request execution

if [ -z "$AUTHORIZATION_TOKEN" ]; then
  "$CURL" -s \
    -X POST \
    --header "Content-Type: $CONTENT_TYPE_HEADER" \
    --data-binary @request.bin \
    --output response.bin \
    --dump-header response-headers.txt \
    "$URL"
else
  "$CURL" -s \
    -X POST \
    --header "Content-Type: $CONTENT_TYPE_HEADER" \
    --header "AuthScheme: $AUTH_SCHEME" \
    --header "Authorization: $AUTHORIZATION_TOKEN" \
    --data-binary @request.bin \
    --output response.bin \
    --dump-header response-headers.txt \
    "$URL"
fi

# ============ response headers
$DISPLAY_RESPONSE_HEADERS && echo "$VISUAL_SEPARATOR Response Headers $VISUAL_SEPARATOR $RECV" && cat response-headers.txt

# TODO. handle response failure!
# Enable one to use a different thing based on the HTTP status code?

# ============ response body

# shellcheck disable=SC2086
$DISPLAY_BINARY && echo "$VISUAL_SEPARATOR Response Binary $VISUAL_SEPARATOR $RECV" && hexdump $BINARY_FORMAT_ARGS response.bin

echo "$VISUAL_SEPARATOR Response Text   $VISUAL_SEPARATOR $RECV"
cat response.bin | protoc --decode "$RESPONSE_TYPE" $PROTO
