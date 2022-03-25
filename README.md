# protocurl

todo

# Usage

1. docker
2. bash

todo: easier usage of the tool todo: ask people from AIR Team

# Installation

```
docker build -f src/Dockerfile -t protocurl:v1 .
```

# Dev Setup

...

run node server cli when installing new packages etc:

```
docker run -v "$PWD/test/servers:/servers" -it nodeserver:v1 /bin/bash
```

Build node server image:

```
docker build -t nodeserver:v1 -f test/servers/Dockerfile .
```

Run node server:

```
docker-compose -f test/servers/compose.yml up server
```

Run all tests (unix bash only):

1. Install `https://stedolan.github.io/jq/` into `test/suite/jq`
2. Run tests `./test/suite/test.sh`

# How to contribute

...

## Adding tests

To add a test, simply add a new entry into `test/suite/testcases.json` and run the tests. The tests will generate an
empty expected output file and copy the actual output sideby side. You can inspect the actual output and copy it into
the expected-output file when you are happy. ...

## Potential Improvements

* **JSON support**: protoCURL currently only uses the text format. Using JSON as a conversion format would make it more
  useful and viable for everyday usage.
* **Protobuf format coverage**: The tests currently do not use strings, enums and other complex types. We want to
  incraete the test coverage here and adapt protoCURL if necessary
* **Response failure hanlding**: protoCURL always attempts to interpret the response from the server as a protobuf
  payload - even if the request has failed.