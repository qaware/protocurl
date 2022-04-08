# protoCURL

![test status](https://github.com/qaware/protocurl/actions/workflows/test.yml/badge.svg)

todo.

# Usage

1. docker
2. bash

todo: easier usage of the tool

## CLI Arguments

See [usage notes](doc/generated.usage.txt).

# Installation

1. Clone this repository
2. Build the `protocurl:latest` image via: `docker build -f src/Dockerfile -t protocurl .`

todo: update once everything is in go

# Examples

See [EXAMPLES.md](EXAMPLES.md)

# Protobuf Text Format

Aside from JSON, Protobuf also natively supports a text format. This is the only format, which `protoc` natively
implements and exposes.
(This is despite the fact, that every Protobuf SDK for the standard langauges also contains the JSON conversion
capabilities.)

This text format syntax
is [barely documented](https://developers.google.com/protocol-buffers/docs/reference/cpp/google.protobuf.text_format),
so this section will shortly describe how to write Protobuf messages in the text format.

Given the following .proto file

```
syntax = "proto3";

import "google/protobuf/timestamp.proto";

message HappyDayRequest {
  google.protobuf.Timestamp date = 1;
  bool includeReason = 2;
  
  double myDouble = 3;
  int64 myInt64 = 5;
  string myString = 6;
  repeated NestedMessage messages = 9;
}

message NestedMessage {
  Foo fooEnum = 1;
  repeated int32 i = 4;
}

enum Foo {
  BAR = 0;
  BAZ = 1;
}
```

A `HappyDayRequest` message in text format might look like this:

```
includeReason: true,
myInt64: 123123123123,
myString: "hello world",
myDouble: 123.456,
messages: { fooEnum: BAR, i: 0, i: 1, i: 1337 },
messages: { i: 15, fooEnum: BAZ, i: -1337 },
messages: { },
date: { seconds: 123, nanos: 321 }
```

In summary:

* No encapsulating `{ ... }` are used for the top level message (in contrast to JSON).
* fields are comma separated and described via `<fieldname>: <value>`´.
  * Strictly speaking, the commas are optional and whitespace is sufficient
* repeated fields are simply repeated multiple times (instead of using an array) and they do not need to appear
  consecutively.
* nested messages are described with `{ ... }` opening a new context and describing their fields recursively
* scalar values are describes similar to JSON
* enum values are referenced by their name
* built-in messages (such
  as [google.protobuf.Timestamp](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Timestamp)
  are described just like user-defined custom messages via `{ ... }` and their message fields

[This page shows more details on the text format.](https://stackoverflow.com/a/18877167)

# How to contribute

todo. And also link to [Developer](DEVELOPER.md).

# Tests

See [TESTS.md](TESTS.md)

# Release

See [RELEASE.md](RELEASE.md)

# Potential Improvements

* **JSON support**: protoCURL currently only uses the text format. Using JSON as a conversion format would make it more
  useful and viable for everyday usage.
* **Multi-file support**: Currently, the request and response messages need to be in the same file. An improvement would
  be to allow the user to import a directory of Protobuf file and have protoCURL search for the definitions given the
  request and response types.
* **Raw Format**: If no .proto files for the response are available, then it's still possible to receive and decode
  messages. The decoding can happen in a way which only shows the field numbers and the field contents - without the
  field names - by using `protoc --decode_raw`. This might be useful for users of protoCURL.
* **Quality of Life Improvments**: Avoid explicitly specifying the file via `-f` and instead search the message types
  from `-i` and `-o`. Additionally, it should be sufficient to only use the name of the message type instead of the full
  path, whenever the message type is unique.
* **Interactive input for the user**: For first time users, it might be better for them to simply start with a command
  like `protocurl -u URL`
  and then be prompted for the input arguments. This way, it's easier for the user to run it and to get help on each
  command. In the final step, the CLI could produce an output, where the final command can be as the full version.(
  see [example](https://medium.com/@jdxcode/12-factor-cli-apps-dd3c227a0e46#2d6e))

## Open TODOs

* Rewrite the Tool in Go. Use [GoRelease](https://goreleaser.com/intro/) to create static binaries and to release it as
  a docker container.
  * Explain, that goReleaser is used.
* Release the latest version on docker, via GitHub action under `qaware/protocurl`
* `docker scan`
* Add note, that on some platforms such as Windows, an empty request text will not properly function if used with "".
  One will need " " (with a space) instead.
* Apply 12 factor CLI app principles
* Add documentation explaining how the protobuf processing works with links to go protobuf SDK
  * https://pkg.go.dev/google.golang.org/protobuf/reflect/protoreflect
  * https://pkg.go.dev/google.golang.org/protobuf/types/dynamicpb#Message.ProtoReflect
  * https://pkg.go.dev/google.golang.org/protobuf/reflect/protoreflect#Descriptor
  * https://pkg.go.dev/google.golang.org/protobuf/encoding/prototext
  * https://pkg.go.dev/google.golang.org/protobuf/proto#Unmarshal
  * https://pkg.go.dev/google.golang.org/protobuf/proto#pkg-types
* Adapt tests such that they run on GitHub Windows + macOS + Linux runners with the native protoCURL CLI against the
  test server
* Licensing, since jaegertracing/protobuf is included.
* Bundle a curl and protoc together inside the release ZIP.
  * Mention authors and licenses for curl and protoc when bundling
* Add argument "--protoc" which uses the protoc executable in PATH and "--protoc=/path/to/protoc" to explicitly specify
  which protoc to use
