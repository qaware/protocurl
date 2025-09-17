# Tests

There are three types of tests. The docker-containerized tests, multi-platform native archive tests (running on windows,
macos, etc.)
and multi-platform native package tests.

The containerized tests do much of the heavy lifting in ensuring correctness - whereas the native tests ensure that the
basic functionality work multi-platform and contains regression tests for OS-specific behavior.

The native tests extract the release archive and the release packages (e.g. .deb, .apk) and run basic tests.

To run the tests, first setup the prerequisites from [Setup section in the README.md](README.md#setup).

## Containerized Tests

The tests are run automatically via GitHub Actions [here](.github/workflows/test.yml). Run them
via `./test/suite/test.sh "$PWD"` (bash) from the repository root directory.

* It needs the full path to the current working directory, as otherwise the docker volume mount fails in WSL on Windows.
  Concretely, on WSL Windows, we need to use `./test/suite/test.sh "c:/path/to/protocurl/repository"`

### How the tests work

The tests start the local NodeJS based server from `test/servers/server.ts` inside a docker container and send requests
from `test/suite/testcases.json` against the testserver. Each testcase is of the form

```
{
  "filename": "<a filename without spaces and without extension>",
  "beforeTestBash": "<bash statements>
  "args": [
    "<arguments for protocurl>",
    "<These are split into an array to make it easier to write them in the JSON file.>",
    "<All of these array elements will be concatenated with spaces.>"
  ],
  "rerunwithArgForEachElement": ["<some-arg-for-one-scenario>", "<some-arg-for-another-scenario>"],
  "afterTestBash": "<bash statements>"
}
```

For each testcase, the `args` array will be concatenated and the concatenated string will be given to `protocurl` (via
docker run) as arguments. `beforeTestBash`, `afterTestBash` and `runAgainWithArg` are optional - and are replaced with `""` if not given.
This happens via `test/suite/run-testcases.sh` - which is dynamically created from the JSON. This script contains lines
of the form

```
testSingleSpec '<filename>' '<args concatenated with spaces>' '<bash statements>' 'some-arg-for-one-scenario' 'some-arg-for-another-scenario'
```

During the execution of each line in this script, the output will be written into `test/results/$FILENAME-out.txt` -
which will be compared via `diff` to `test/results/$FILENAME-expected.txt`. If both match, then the result is accepted.

Lines containing `Date: ` and will be ignored during the diffing, as they are runtime dependent and their difference is
not relevant to the correctness of the code. Additionally, parts of the Go trace on crashes is also ignored, since the
memory addresses in them are unstable.

If `beforeTestBash` is given, then the bash statements will be executed inside the client docker container before
invoking protocurl with the given arguments. This enables one to explicitly remove curl from the container for testing
purposes. The same happens with `afterTestBash`, except they are run after protocurl was invoked.

If `rerunwithArgForEachElement` is given, then the test case will be run an additional time for each element in the array.
Each additional run will prepend one of the elements in this array to the arguments and invoke protocurl.
This is very useful to test multiple similar scenarios where the behavior should be same/different.
In the above example, in addition to invoking protocurl with `args`, we will invoke it with `some-arg-for-one-scenario args` and `some-arg-for-another-scenario args` as well. During execution of these tests, each testcase is named after the base filename with these additional args appended.


**Examples for the inputs, outputs and arguments can hence be found in the test/results directory as well as
test/suite/testcases.json.**

#### Adapting test server

When new dependencies are needed for the test server, the following command enables one to start a shell in the test
server.

```
docker run -v "$PWD/test/servers:/servers" -it nodeserver:v1 /bin/bash
```

Now it's possible to add new dependencies via `npm install --ignore-scripts <new-package>`

### Adding new tests

To add a test, simply add a new entry into `test/suite/testcases.json` and run the tests. The tests will generate an
empty expected output file and copy the actual output side by side. You can inspect the actual output and copy it into
the expected-output file when you are happy.

If you are happy with the changes and all diffs are expected, you can also copy all output into their `*-expected.txt`
via
`test/suite/copy-test-results-output-to-expected.sh`.

Example runs are shown at the end of this document.

## Multi-Platform Native Tests

The multi-platform native tests are described in [test/suite/native-tests.ps1](test/suite/native-tests.ps1). It uses
Powershell to make cross-platform scripting possible and easier.

These tests are run in [.github/workflows/release.yml](.github/workflows/release.yml) after the release was created. The
jobs are named `post-release-test-<OS>`. After setting up the machine, they start the server
via [test/servers/native-start-server.ps1](test/servers/native-start-server.ps1) and run the tests.

The output is not tested rigorously like the containerized tests. Only the successful exit is tested implicitly as the
Powershell is set to stop on the first error via `$ErrorActionPreference = "Stop"` and `$LASTEXITCODE`.

On linux the release packages are tested inside a container.

## Example Containerized Tests

Example runs can be found here: [test.yml](https://github.com/qaware/protocurl/actions/workflows/test.yml).

Running the tests might look like this:

```
$ ./test/suite/test.sh "$PWD"
Populating cache...
Established Protobuf version 27.0
Populating cache...
Established go version 1.22.3
Populating cache...
Established Goreleaser version v1.26.2
Populating cache...
Established Latest released protoCURL version v1.8.1
No protoc binaries for 27.0 found. Downloading...
Downloading https://github.com/protocolbuffers/protobuf/releases/download/v27.0/protoc-27.0-linux-aarch_64.zip ...
Extracting 27.0-linux-aarch_64 to 27.0-linux-arm64
Downloading https://github.com/protocolbuffers/protobuf/releases/download/v27.0/protoc-27.0-linux-x86_32.zip ...
Extracting 27.0-linux-x86_32 to 27.0-linux-386
Downloading https://github.com/protocolbuffers/protobuf/releases/download/v27.0/protoc-27.0-linux-x86_64.zip ...
Extracting 27.0-linux-x86_64 to 27.0-linux-amd64
Downloading https://github.com/protocolbuffers/protobuf/releases/download/v27.0/protoc-27.0-osx-aarch_64.zip ...
Extracting 27.0-osx-aarch_64 to 27.0-darwin-arm64
Downloading https://github.com/protocolbuffers/protobuf/releases/download/v27.0/protoc-27.0-osx-x86_64.zip ...
Extracting 27.0-osx-x86_64 to 27.0-darwin-amd64
Downloading https://github.com/protocolbuffers/protobuf/releases/download/v27.0/protoc-27.0-win32.zip ...
Extracting 27.0-win32 to 27.0-windows-386
Downloading https://github.com/protocolbuffers/protobuf/releases/download/v27.0/protoc-27.0-win64.zip ...
Extracting 27.0-win64 to 27.0-windows-amd64
Done.
Variables: VERSION=1.9.0-rc-dev, VVERSION=v1.9.0-rc-dev, SNAPSHOT=true, BUILD_ARCH=amd64, PROTO_VERSION=27.0
Stopping server...
Done.
Building protocurl:latest ...
sha256:f4245bec7c1599da2cb44ef212dd066d95257935d58485ebfc1cebb761a4ab52
Done.
Building test image variant of protocurl including additonal executables ...
sha256:d69bfe0bfd502082e3eb249eb1ee26f5ced21b4ec2ad71d74f8b748e5f000b1d
Done.
Starting server...
Done.
Waiting for server to become ready...
Waited 1 seconds already...
Waited 2 seconds already...
=== Test server is ready ===
=== Running ALL Tests ===
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day-no-curl
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day--X_GET
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day--X_POST
✨✨✨ SUCCESS ✨✨✨ - unknown-message-package-path-error
✨✨✨ SUCCESS ✨✨✨ - unknown-message-package-path-error--X_GET
✨✨✨ SUCCESS ✨✨✨ - unknown-base-message-name-error
✨✨✨ SUCCESS ✨✨✨ - unknown-base-message-name-error--X_GET
✨✨✨ SUCCESS ✨✨✨ - message-package-path-resolved-to-non-message-error
✨✨✨ SUCCESS ✨✨✨ - message-package-path-resolved-to-non-message-error--X_GET
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path--X_GET
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path-nested
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path-nested--X_GET
✨✨✨ SUCCESS ✨✨✨ - inferred-proto-file
✨✨✨ SUCCESS ✨✨✨ - inferred-proto-file--F
✨✨✨ SUCCESS ✨✨✨ - inferred-proto-file--X_GET
✨✨✨ SUCCESS ✨✨✨ - inferred-proto-file--F_-X_GET
✨✨✨ SUCCESS ✨✨✨ - inferred-proto-file-message-package-path
✨✨✨ SUCCESS ✨✨✨ - inferred-proto-file-message-package-path--X_GET
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path-name-clash-ambiguous-error
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path-name-clash-ambiguous-error--X_GET
✨✨✨ SUCCESS ✨✨✨ - message-package-path-nested-subdir
✨✨✨ SUCCESS ✨✨✨ - message-package-path-nested-subdir--X_GET
✨✨✨ SUCCESS ✨✨✨ - without-input
✨✨✨ SUCCESS ✨✨✨ - without-input--X_GET
✨✨✨ SUCCESS ✨✨✨ - without-input--X_GET_--no-curl
✨✨✨ SUCCESS ✨✨✨ - without-input--i___HappyDayRequest
✨✨✨ SUCCESS ✨✨✨ - without-input--X_GET_-i___HappyDayRequest
✨✨✨ SUCCESS ✨✨✨ - without-request-type
✨✨✨ SUCCESS ✨✨✨ - without-request-type--X_GET
✨✨✨ SUCCESS ✨✨✨ - unknown-message-as-text
✨✨✨ SUCCESS ✨✨✨ - unknown-message-as-text--X_GET
✨✨✨ SUCCESS ✨✨✨ - unknown-message-as-json
✨✨✨ SUCCESS ✨✨✨ - unknown-message-as-json--X_GET
✨✨✨ SUCCESS ✨✨✨ - response-type-arg-inferred-decode-raw
✨✨✨ SUCCESS ✨✨✨ - response-type-arg-inferred-decode-raw--X_GET
✨✨✨ SUCCESS ✨✨✨ - response-type-arg-overidden-decode-raw
✨✨✨ SUCCESS ✨✨✨ - response-type-arg-overidden-decode-raw--X_GET
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path-nested-subdir
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path-nested-subdir--X_GET
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path-name-clash-explicit-path
✨✨✨ SUCCESS ✨✨✨ - inferred-message-package-path-name-clash-explicit-path--X_GET
✨✨✨ SUCCESS ✨✨✨ - infer-files-provide-file-wrong-args
✨✨✨ SUCCESS ✨✨✨ - infer-files-provide-file-wrong-args--X_GET
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day-json
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day-json-no-curl
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day-json--X_GET
✨✨✨ SUCCESS ✨✨✨ - payload-json
✨✨✨ SUCCESS ✨✨✨ - payload-json--v
✨✨✨ SUCCESS ✨✨✨ - payload-json-relative
✨✨✨ SUCCESS ✨✨✨ - payload-txt
✨✨✨ SUCCESS ✨✨✨ - payload-invalid
✨✨✨ SUCCESS ✨✨✨ - payload-file-not-found
✨✨✨ SUCCESS ✨✨✨ - in-wrong
✨✨✨ SUCCESS ✨✨✨ - in-wrong--X_GET
✨✨✨ SUCCESS ✨✨✨ - out-wrong
✨✨✨ SUCCESS ✨✨✨ - out-wrong--X_GET
✨✨✨ SUCCESS ✨✨✨ - json-in
✨✨✨ SUCCESS ✨✨✨ - json-in--X_GET
✨✨✨ SUCCESS ✨✨✨ - json-in-proper-proto-names
✨✨✨ SUCCESS ✨✨✨ - json-in-proper-proto-names--X_GET
✨✨✨ SUCCESS ✨✨✨ - json-out-pretty
✨✨✨ SUCCESS ✨✨✨ - json-out-pretty--X_GET
✨✨✨ SUCCESS ✨✨✨ - json-in-wrong-arg
✨✨✨ SUCCESS ✨✨✨ - json-in-wrong-arg--X_GET
✨✨✨ SUCCESS ✨✨✨ - text-in
✨✨✨ SUCCESS ✨✨✨ - text-in--X_GET
✨✨✨ SUCCESS ✨✨✨ - text-in-wrong-arg
✨✨✨ SUCCESS ✨✨✨ - text-in-wrong-arg--X_GET
✨✨✨ SUCCESS ✨✨✨ - text-in-json-output
✨✨✨ SUCCESS ✨✨✨ - text-in-json-output--X_GET
✨✨✨ SUCCESS ✨✨✨ - json-in-text-output
✨✨✨ SUCCESS ✨✨✨ - json-in-text-output--X_GET
✨✨✨ SUCCESS ✨✨✨ - missing-curl-no-curl
✨✨✨ SUCCESS ✨✨✨ - missing-curl-no-curl--X_GET
✨✨✨ SUCCESS ✨✨✨ - missing-curl-header-args-not-possible
✨✨✨ SUCCESS ✨✨✨ - missing-curl-header-args-not-possible--X_GET
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days-no-curl
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days--X_GET
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days-moved-protofiles
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days-moved-protofiles-no-curl
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days-moved-protofiles--X_GET
✨✨✨ SUCCESS ✨✨✨ - invalid-protofile-path
✨✨✨ SUCCESS ✨✨✨ - invalid-protofile-path--X_GET
✨✨✨ SUCCESS ✨✨✨ - invalid-protofile-dir
✨✨✨ SUCCESS ✨✨✨ - invalid-protofile-dir--X_GET
✨✨✨ SUCCESS ✨✨✨ - verbose
✨✨✨ SUCCESS ✨✨✨ - verbose-no-curl
✨✨✨ SUCCESS ✨✨✨ - verbose-long-args-equals-args
✨✨✨ SUCCESS ✨✨✨ - verbose-long-args-equals-args--X_GET
✨✨✨ SUCCESS ✨✨✨ - verbose-custom-headers
✨✨✨ SUCCESS ✨✨✨ - verbose-custom-headers-no-curl
✨✨✨ SUCCESS ✨✨✨ - verbose-custom-headers--X_GET
✨✨✨ SUCCESS ✨✨✨ - verbose-missing-curl
✨✨✨ SUCCESS ✨✨✨ - verbose-missing-curl--X_GET
✨✨✨ SUCCESS ✨✨✨ - quiet-with-content
✨✨✨ SUCCESS ✨✨✨ - quiet-with-content-no-curl
✨✨✨ SUCCESS ✨✨✨ - quiet-with-content--X_GET
✨✨✨ SUCCESS ✨✨✨ - silent-with-content
✨✨✨ SUCCESS ✨✨✨ - silent-with-content-no-curl
✨✨✨ SUCCESS ✨✨✨ - silent-with-content--X_GET
✨✨✨ SUCCESS ✨✨✨ - display-binary-and-headers
✨✨✨ SUCCESS ✨✨✨ - display-binary-and-headers-no-curl
✨✨✨ SUCCESS ✨✨✨ - display-binary-and-headers--X_GET
✨✨✨ SUCCESS ✨✨✨ - additional-curl-args
✨✨✨ SUCCESS ✨✨✨ - additional-curl-args-no-curl
✨✨✨ SUCCESS ✨✨✨ - additional-curl-args--X_GET
✨✨✨ SUCCESS ✨✨✨ - additional-curl-args-verbose
✨✨✨ SUCCESS ✨✨✨ - additional-curl-args-verbose--X_GET
✨✨✨ SUCCESS ✨✨✨ - no-reason
✨✨✨ SUCCESS ✨✨✨ - no-reason-curl
✨✨✨ SUCCESS ✨✨✨ - no-reason--X_GET
✨✨✨ SUCCESS ✨✨✨ - far-future
✨✨✨ SUCCESS ✨✨✨ - far-future-no-curl
✨✨✨ SUCCESS ✨✨✨ - far-future--X_GET
✨✨✨ SUCCESS ✨✨✨ - far-future-json
✨✨✨ SUCCESS ✨✨✨ - far-future-json--v
✨✨✨ SUCCESS ✨✨✨ - far-future-json--X_GET
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday-no-curl
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday--X_GET
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday-missing-curl
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday-missing-curl-no-curl
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday-missing-curl--X_GET
✨✨✨ SUCCESS ✨✨✨ - moved-curl
✨✨✨ SUCCESS ✨✨✨ - moved-curl-no-curl
✨✨✨ SUCCESS ✨✨✨ - moved-curl--X_GET
✨✨✨ SUCCESS ✨✨✨ - global-protoc
✨✨✨ SUCCESS ✨✨✨ - global-protoc--X_GET
✨✨✨ SUCCESS ✨✨✨ - missing-protocurl-internal
✨✨✨ SUCCESS ✨✨✨ - missing-protocurl-internal--X_GET
✨✨✨ SUCCESS ✨✨✨ - global-protoc-and-lib
✨✨✨ SUCCESS ✨✨✨ - global-protoc-and-lib--X_GET
✨✨✨ SUCCESS ✨✨✨ - moved-lib
✨✨✨ SUCCESS ✨✨✨ - moved-lib--X_GET
✨✨✨ SUCCESS ✨✨✨ - missing-protoc
✨✨✨ SUCCESS ✨✨✨ - missing-protoc--X_GET
✨✨✨ SUCCESS ✨✨✨ - missing-protoc-global
✨✨✨ SUCCESS ✨✨✨ - missing-protoc-global--X_GET
✨✨✨ SUCCESS ✨✨✨ - echo-filled
✨✨✨ SUCCESS ✨✨✨ - echo-filled-no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-filled--X_GET
✨✨✨ SUCCESS ✨✨✨ - echo-empty
✨✨✨ SUCCESS ✨✨✨ - echo-empty-no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-empty--X_GET
✨✨✨ SUCCESS ✨✨✨ - echo-empty--X_GET_-v
✨✨✨ SUCCESS ✨✨✨ - echo-empty--X_HEAD
✨✨✨ SUCCESS ✨✨✨ - echo-empty--X_HEAD_-v
✨✨✨ SUCCESS ✨✨✨ - echo-empty--X_HEAD_--no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-empty-with-curl-args
✨✨✨ SUCCESS ✨✨✨ - echo-empty-with-curl-args-no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-empty-with-curl-args--X_GET
✨✨✨ SUCCESS ✨✨✨ - echo-full
✨✨✨ SUCCESS ✨✨✨ - echo-full-no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-full--X_GET
✨✨✨ SUCCESS ✨✨✨ - echo-full-json
✨✨✨ SUCCESS ✨✨✨ - echo-full-json--X_GET
✨✨✨ SUCCESS ✨✨✨ - echo-quiet
✨✨✨ SUCCESS ✨✨✨ - echo-quiet-no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-quiet--X_GET
✨✨✨ SUCCESS ✨✨✨ - failure-simple
✨✨✨ SUCCESS ✨✨✨ - failure-simple-no-curl
✨✨✨ SUCCESS ✨✨✨ - failure-simple--X_GET
✨✨✨ SUCCESS ✨✨✨ - failure-simple-quiet
✨✨✨ SUCCESS ✨✨✨ - failure-simple-quiet--D
✨✨✨ SUCCESS ✨✨✨ - failure-simple-quiet--v
✨✨✨ SUCCESS ✨✨✨ - failure-simple-quiet-no-curl
✨✨✨ SUCCESS ✨✨✨ - failure-simple-quiet--X_GET
✨✨✨ SUCCESS ✨✨✨ - failure-simple-silent
✨✨✨ SUCCESS ✨✨✨ - failure-simple-silent--D
✨✨✨ SUCCESS ✨✨✨ - failure-simple-silent--v
✨✨✨ SUCCESS ✨✨✨ - failure-simple-silent--q
✨✨✨ SUCCESS ✨✨✨ - failure-simple-silent-no-curl
✨✨✨ SUCCESS ✨✨✨ - failure-simple-silent--X_GET
✨✨✨ SUCCESS ✨✨✨ - missing-args
✨✨✨ SUCCESS ✨✨✨ - missing-args-no-curl
✨✨✨ SUCCESS ✨✨✨ - missing-args--X_GET
✨✨✨ SUCCESS ✨✨✨ - missing-args-partial
✨✨✨ SUCCESS ✨✨✨ - missing-args-partial-no-curl
✨✨✨ SUCCESS ✨✨✨ - missing-args-partial--X_GET
✨✨✨ SUCCESS ✨✨✨ - help
✨✨✨ SUCCESS ✨✨✨ - help-no-curl
✨✨✨ SUCCESS ✨✨✨ - help--X_GET
✨✨✨ SUCCESS ✨✨✨ - help-missing-curl
✨✨✨ SUCCESS ✨✨✨ - help-missing-curl-no-curl
✨✨✨ SUCCESS ✨✨✨ - help-missing-curl--X_GET
✨✨✨ SUCCESS ✨✨✨ - version
✨✨✨ SUCCESS ✨✨✨ - version-no-curl
✨✨✨ SUCCESS ✨✨✨ - version--X_GET
✨✨✨ SUCCESS ✨✨✨ - no-default-headers-with-no-additional-headers
✨✨✨ SUCCESS ✨✨✨ - no-default-headers-with-no-additional-headers--X_GET
✨✨✨ SUCCESS ✨✨✨ - no-default-headers-with-custom-content-type-header
✨✨✨ SUCCESS ✨✨✨ - no-default-headers-with-custom-content-type-header--X_GET
✨✨✨ SUCCESS ✨✨✨ - no-default-headers-with-no-curl-flag
✨✨✨ SUCCESS ✨✨✨ - no-default-headers-with-no-curl-flag--X_GET
✨✨✨ SUCCESS ✨✨✨ - tmp-file-permissions-readable
✨✨✨ SUCCESS ✨✨✨ - tmp-file-permissions-readable--X_GET
=== Finished Running ALL Tests ===
Stopping server...
Done.
```
