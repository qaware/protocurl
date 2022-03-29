# protoCURL

todo.

# Usage

1. docker
2. bash

todo: easier usage of the tool todo: ask people from Team

## CLI Arguments

See [usage notes](test/results/help-expected.txt).

# Installation

1. Clone this repository
2. Build the `protocurl:latest` image via: `docker build -f src/Dockerfile -t protocurl .`

# Examples

After starting the local test server via `docker-compose -f test/servers/compose.yml up --build server`, you can send
the following list of requests via protoCURL.

Each request needs to mount the directory of proto files into the containers `/proto` path to ensure, that they are
visible inside the docker container.

```
$ docker run -v "$PWD/test/proto:/proto" --network host protocurl \
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  http://localhost:8080/happy-day/verify \
  "includeReason: true"

=========================== Request Text   =========================== >>>
includeReason: true
=========================== Response Text   =========================== <<<
isHappyDay: true
reason: "Thursday is a Happy Day! \342\255\220"
formattedDate: "Thu, 01 Jan 1970 00:00:00 GMT"
```

```
$ docker run -v "$PWD/test/proto:/proto" --network host protocurl \
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  http://localhost:8080/happy-day/verify ""

=========================== Request Text   =========================== >>>
=========================== Response Text   =========================== <<<
isHappyDay: true
reason: "Thursday is a Happy Day! \342\255\220"
formattedDate: "Thu, 01 Jan 1970 00:00:00 GMT"
```

```
$ docker run -v "$PWD/test/proto:/proto" --network host protocurl \
  -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  http://localhost:8080/happy-day/verify \
  "date: { seconds: 1648044939}"

=========================== Request Text   =========================== >>>
date {
  seconds: 1648044939
}
=========================== Response Text   =========================== <<<
reason: "Tough luck on Wednesday... \360\237\230\225"
formattedDate: "Wed, 23 Mar 2022 14:15:39 GMT"
```

Use `-v` for verbose output:

```
$ docker run -v "$PWD/test/proto:/proto" --network host protocurl \
  -v -f happyday.proto -i happyday.HappyDayRequest -o happyday.HappyDayResponse \
  http://localhost:8080/happy-day/verify \
  "date: { seconds: 1648044939}"

=========================== Request Text   =========================== >>>
date {
  seconds: 1648044939
}
=========================== Request Binary =========================== >>>
00000000  0a 06 08 8b d7 ec 91 06                           |........|
00000008
=========================== Response Headers =========================== <<<
HTTP/1.1 200 OK
Content-Type: application/x-Protobuf
Date: Fri, 25 Mar 2022 15:02:57 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Content-Length: 68

=========================== Response Binary =========================== <<<
00000000  08 00 12 1f 54 6f 75 67  68 20 6c 75 63 6b 20 6f  |....Tough luck o|
00000010  6e 20 57 65 64 6e 65 73  64 61 79 2e 2e 2e 20 f0  |n Wednesday... .|
00000020  9f 98 95 1a 1d 57 65 64  2c 20 32 33 20 4d 61 72  |.....Wed, 23 Mar|
00000030  20 32 30 32 32 20 31 34  3a 31 35 3a 33 39 20 47  | 2022 14:15:39 G|
00000040  4d 54 22 00                                       |MT".|
00000044
=========================== Response Text   =========================== <<<
reason: "Tough luck on Wednesday... \360\237\230\225"
formattedDate: "Wed, 23 Mar 2022 14:15:39 GMT"

```

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
* fields are comma separated and described via `<fieldname>: <value>`
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

# Potential Improvements

* **JSON support**: protoCURL currently only uses the text format. Using JSON as a conversion format would make it more
  useful and viable for everyday usage.
* **Protobuf format coverage**: The tests currently do not use strings, enums and other complex types. We want to
  increase the test coverage here and adapt protoCURL if necessary
* **Response failure handling**: protoCURL always attempts to interpret the response from the server as a Protobuf
  payload - even if the request has failed.
* **Multi-file support**: Currently, the request and response messages need to be in the same file. An improvement would
  be to allow the user to import a directory of Protobuf file and have protoCURL search for the definitions given the
  request and response types.
* **Pre-built releases of the image for various prorobuf versions on docker**
* **Raw Format**: If no .proto files for the response are available, then it's still possible to receive and decode
  messages. The decoding can happen in a way which only shows the field numbers and the field contents - without the
  field names - by using `protoc --decode_raw`. This might be useful for users of protoCURL.
* **Use a general purpose programming language**: To support JSON conversion and many other nice-to-have features, it
  would be better, easier and more reliable to use a proper programming language such as Go, C++, Rust, etc. to create
  the CLI and to build static binaries for the different operating systems and architectures.
* **Quality of Life Improvments**: Avoid explicitly specifying the file via `-f` and instead search the message types
  from `-i` and `-o`. Additionally, it should be sufficient to only use the name of the message type instead of the full
  path, whenever the message type is unique.

## Open TODOs

* Rewrite the Tool in Go. Use [GoRelease](https://goreleaser.com/intro/) to create static binaries and to release it as
  a docker container.
* Release the latest version on docker, via GitHub action under `qaware/protocurl`
* Check, if all mandatory arguments are given, and report errors otherwise.
* Since the base image seems to not be updated since a while, it would be better to directly include the most important
  commands via from its [Dockerfile](https://github.com/znly/docker-protobuf/blob/master/Dockerfile) into protoCURL
  directly
* `docker scan`
* Add note, that on some platforms such as Windows, an empty request text will not properly function if used with "".
  One will need " " (with a space) instead.