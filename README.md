# protoCURL

![test status](https://github.com/qaware/protocurl/actions/workflows/test.yml/badge.svg)

Like cURL, but for Protobuf: Command-line tool for interacting with Protobuf over REST-ful HTTP endpoints

## Installation

`protocurl` includes and uses a bundled `protoc` by default. It is recommended to install `curl` into PATH for
configurable http requests. Otherwise `protocurl` will use a simple non-configurable fallback http implementation.

#### Native Binary

1. Download the latest release archive for your platform from https://github.com/qaware/protocurl/releases
2. Extract the archive into a folder, e.g. `/usr/local/protocurl`.
3. Add symlink to the binary in the folder. e.g. `ln -s /usr/local/protocurl/bin/protocurl /usr/local/bin/protocurl`
   Or add the binary folder `/usr/local/protocurl/bin` to your system-wide path.
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
  repeated string myString = 6;
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
myString: "hello world"
myString: 'single quotes are also possible'
myDouble: 123.456
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
* scalar values are describes similar to JSON. Single and double quotes are both possible for strings.
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
* **Promoting containerized tests to native tests**: While we already have containerized tests in bash - having them in
  Powershell may enable us to run these more rigorous tests directly on the respective platforms instead of the
  container only.
* **Add step by step example of creating a protocurl request.**
* **Enable variant of protocurl with user-provided proto files compiled in.** E.g. we could use the protocurl docker
  image and give an example, where one could simply compile a set of proto files into a new image via Dockerfile. Then
  one could simply avoid providing the `-v` volume bind as well as the `-I`.
* **Proto default library path** Custom protoc path may lead to the
  error `/usr/bin/include: warning: directory does not exist.`. This can happen, when the user installed the libraries
  into a different path. We could deal with this in a better way. Furthermore, one needs to use a workaround when using
  a custom protoc and custom .protol-lib as both the users .proto files and the .proto-lib needs to be contained
  correctly.
* **Better release process** Due to certain limitations the current CI/CD pipeline runs some tests on the final release
  after it has been published to DockerHub and on GitHub. Ideally, we should not do that as other might be downloading
  the release in the meanwhile. One solution to this is the use of promotions from an release candidate which is
  published and tested - before being finally promoted (renamed) to a full release. Furthermore, the `prerelease: auto`
  option of [goreleaser release](https://goreleaser.com/customization/release/)) could be used.

## FAQ

* **How is protocurl different from grpccurl?** [grpccurl](https://github.com/fullstorydev/grpcurl) only works with gRPC
  services with corresponding endpoints. However, classic REST HTTP endpoints with binary Protobuf payloads are only
  possible with `protocurl`.
* **Why is the use of a runtime curl recommended with protocurl?** curl is a simple, flexible and mature command line
  tool to interact with HTTP endpoints. In principle, we could simply use the HTTP implementation provided by the host
  programming language (Go) - and this is what we do if no curl was found in the PATH. However, as more people use
  protocurl, they will request for more features - leading to a feature creep in such a 'simple' tool as protocurl. We
  would like to avoid implementing the plentiful features which are necessary for a proper HTTP CLI tool, because HTTP
  can be complex. Since is essentially what curl already does, we recommend using curl and all advanced features are
  only possible with curl.
* **What are some nice features of protocurl?**
  * The implementation is well tested with end-2-end approval tests (see [TESTS.md](TESTS.md)). All features are tested
    based on their effect on the behavior/output. Furthermore, there are also a few cross-platform native CI tests
    running on Windows and MacOS runners.
  * The build and release process is optimised for minimal maintenance efforts. During release build, the latest
    versions of many dependencies are taken automatically (by looking up the release tags via the GitHub API).
  * The documentation and examples are generated via scripts and enable one to update the examples automatically rather
    than manually. The consistency of the outputs of the code with the checked in documentation is further tested in CI.
  