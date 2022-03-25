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
the following requests via protoCURL:

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
Content-Type: application/x-protobuf
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

Each request needs to mount the directory of proto files into the containers `/proto` path to ensure, that they are
visible inside the docker container.

# Dev Setup

...

run node server cli when installing new packages etc:

```
docker run -v "$PWD/test/servers:/servers" -it nodeserver:v1 /bin/bash
```

Run node server:

```
docker-compose -f test/servers/compose.yml up --build server
```

Run all tests (unix bash only):

1. Install `https://stedolan.github.io/jq/` into `test/suite/jq`
2. Run tests `./test/suite/test.sh`

# How to contribute

...

# Tests

See [TESTS.md](TESTS.md)

# Potential Improvements

* **JSON support**: protoCURL currently only uses the text format. Using JSON as a conversion format would make it more
  useful and viable for everyday usage.
* **Protobuf format coverage**: The tests currently do not use strings, enums and other complex types. We want to
  incraete the test coverage here and adapt protoCURL if necessary
* **Response failure hanlding**: protoCURL always attempts to interpret the response from the server as a protobuf
  payload - even if the request has failed.
* **Multi-file support**: Currently, the request and response messages need to be in the same file. An improvement would
  be to allow the user to import a directory of protobuf file and have protCURL search for the definitions given the
  request and response types.

## Open TODOs

* Remove static path for mount in `test.sh`
* Perhaps use a different and more up to date base image
* LICENSE
* Add documentation and examples for raw text format