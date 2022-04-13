# protoCURL

![test status](https://github.com/qaware/protocurl/actions/workflows/test.yml/badge.svg)

Like cURL, but for Protobuf: Command-line tool for interacting with Protobuf over REST-ful HTTP endpoints

## Installation

#### Native Binary

1. Download the latest release archive for your platform from https://github.com/qaware/protocurl/releases
2. Extract the archive into a folder, e.g. `/usr/local/protocurl`.
3. Add symlink to the binary in the folder: `ln -s /usr/local/protocurl/bin/protocurl /usr/local/bin/protocurl`
4. Test that it works via `protocurl -h`

#### Docker

Simply run `docker run -v "/path/to/proto/files:/proto" qaware/protocurl <args>`. See [examples](EXAMPLES.md) below.

## Usage and Examples

See [usage notes](doc/generated.usage.txt) and [EXAMPLES.md](EXAMPLES.md).

## Protobuf Text Format

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

## Development

For development it is recommended to use the a bash-like Terminal either natively (Linux, Mac) or via MinGW on Windows.

About the CI/CD tests: [TESTS.md](TESTS.md)

How to make a release: [RELEASE.md](RELEASE.md)

#### Setup

* As for script utilities, one needs `bash`, `jq`, `zip`, `unzip` and `curl`.
* One also needs to download the protoc binaries for the local development via `release/0-get-protoc-binaries.sh`.

For development the [local.Dockerfile](src/local.Dockerfile) is used. To build the image simply
run `source test/suite/setup.sh` and then `buildProtocurl`

#### Test Server

When new dependencies are needed for the test server, the following command enables one to start a shell in the test
server.

```
docker run -v "$PWD/test/servers:/servers" -it nodeserver:v1 /bin/bash
```

Now it's possible to add new dependencies via `npm install <new-package>`

#### Updating Docs after changes

Generate the main docs (.md files etc.) in bash/WSL via `doc/generate-docs.sh <absolute-path-to-protocurl-repository>`.

Once a pull request is ready, run this to generate updated docs.

## Potential Features

* **JSON support**: protoCURL currently only uses the text format. Using JSON as a conversion format would make it more
  useful and viable for everyday usage.
* **Multi-file support**: Currently, the request and response messages need to be in the same file. An improvement would
  be to allow the user to import a directory of Protobuf file and have protoCURL search for the definitions given the
  request and response types.
* **Raw Format**: If no .proto files for the response are available, then it's still possible to receive and decode
  messages. The decoding can happen in a way which only shows the field numbers and the field contents - without the
  field names - by using `protoc --decode_raw`. This might be useful for users of protoCURL.
* **Quality of Life Improvements**: Avoid explicitly specifying the file via `-f` and instead search the message types
  from `-i` and `-o`. Additionally, it should be sufficient to only use the name of the message type instead of the full
  path, whenever the message type is unique.
* **Interactive input for the user**: For first time users, it might be better for them to simply start with a command
  like `protocurl -u URL`
  and then be prompted for the input arguments. This way, it's easier for the user to run it and to get help on each
  command. In the final step, the CLI could produce an output, where the final command can be as the full version.(
  see [example](https://medium.com/@jdxcode/12-factor-cli-apps-dd3c227a0e46#2d6e))
* **Auto-update to newer versions of
  dependencies**: [Dependabot](https://github.com/qaware/protocurl/network/dependencies)
* **Accept proto file descriptor set payload as argument**: This enables one to skip using a protoc binary and directly
  work with the filesdescriptorset.
* **Fix duplicated error messages**
* **Cross-platform CLI tests**: Create new GitHub Action tests such that they run on Windows + macOS + Linux runners
  with the native protoCURL CLI against the test server.
  See [this](https://www.zettlr.com/post/continuous-cross-platform-deployment-github-actions).

### Open TODOs

* Resolve final TODOs.
* Make readme more fancy and mention highlights such as extensive testing, automatic latest version for dependencies (
  Go, Goreleaser, Protobuf), etc.
* Make 1.0.0 release.
* Make docker image repository and GitHub repo public