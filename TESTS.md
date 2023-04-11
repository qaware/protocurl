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
  "runAgainWithArg": "<--some-arg>",
  "afterTestBash": "<bash statements>"
}
```

For each testcase, the `args` array will be concatenated and the concatenated string will be given to `protocurl` (via
docker run) as arguments. `beforeTestBash`, `afterTestBash` and `runAgainWithArg` are optional - and are replaced with `""` if not given.
This happens via `test/suite/run-testcases.sh` - which is dynamically created from the JSON. This script contains lines
of the form

```
testSingleRequest '<filename>' '<args concatenated with spaces>' '<bash statements>' '--some-arg'
```

During the execution of each line in this script, the output will be written into `test/results/$FILENAME-out.txt` -
which will be compared via `diff` to `test/results/$FILENAME-expected.txt`. If both match, then the result is accepted.

Lines containing `Date: ` and will be ignored during the diffing, as they are runtime dependent and their difference is
not relevant to the correctness of the code. Additionally, parts of the Go trace on crashes is also ignored, since the
memory addresses in them are unstable.

If `beforeTestBash` is given, then the bash statements will be executed inside the client docker container before
invoking protocurl with the given arguments. This enables one to explicitly remove curl from the container for testing
purposes. The same happens with `afterTestBash`, except they are run after protocurl was invoked.

If `runAgainWithArg` is given, then the test case will be run twice. It will be run once with the given normal arguments
and once more with the given `<--some-arg>` prepended to the arguments of protocurl. This is useful to run the testcases
twice with `--no-curl` to check, that the output is (mostly) the same regardless of the http implementation used.

**Examples for the inputs, outputs and arguments can hence be found in the test/results directory as well as
test/suite/testcases.json.**

#### Adapting test server

When new dependencies are needed for the test server, the following command enables one to start a shell in the test
server.

```
docker run -v "$PWD/test/servers:/servers" -it nodeserver:v1 /bin/bash
```

Now it's possible to add new dependencies via `npm install <new-package>`

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
Established Protobuf version 3.20.0
Established Go version: 1.18
Established Goreleaser version: v1.7.0
Using VERSION=0.0.43, VVERSION=v0.0.43, SNAPSHOT=false, BUILD_ARCH=amd64, PROTO_VERSION=3.20.0
Stopping server...
Done.
Building protocurl:latest ...
sha256:31e53eda86190d57f39be5075a50cfd82ee2aee73094945ba63c9d63e1381879
Done.
Starting server...
Done.
Waiting for server to become ready...
Waited 2 seconds already...
=== Test server is ready ===
=== Running ALL Tests ===
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day-no-curl
✨✨✨ SUCCESS ✨✨✨ - missing-curl-no-curl
✨✨✨ SUCCESS ✨✨✨ - missing-curl-header-args-not-possible
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days-no-curl
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days-moved-protofiles
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days-moved-protofiles-no-curl
✨✨✨ SUCCESS ✨✨✨ - invalid-protofile-path
✨✨✨ SUCCESS ✨✨✨ - invalid-protofile-dir
✨✨✨ SUCCESS ✨✨✨ - verbose
✨✨✨ SUCCESS ✨✨✨ - verbose-no-curl
✨✨✨ SUCCESS ✨✨✨ - verbose-custom-headers
✨✨✨ SUCCESS ✨✨✨ - verbose-custom-headers-no-curl
✨✨✨ SUCCESS ✨✨✨ - verbose-missing-curl
✨✨✨ SUCCESS ✨✨✨ - quiet-with-content
✨✨✨ SUCCESS ✨✨✨ - quiet-with-content-no-curl
✨✨✨ SUCCESS ✨✨✨ - display-binary-and-headers
✨✨✨ SUCCESS ✨✨✨ - display-binary-and-headers-no-curl
✨✨✨ SUCCESS ✨✨✨ - additional-curl-args
✨✨✨ SUCCESS ✨✨✨ - additional-curl-args-no-curl
✨✨✨ SUCCESS ✨✨✨ - additional-curl-args-verbose
✨✨✨ SUCCESS ✨✨✨ - no-reason
✨✨✨ SUCCESS ✨✨✨ - no-reason-curl
✨✨✨ SUCCESS ✨✨✨ - far-future
✨✨✨ SUCCESS ✨✨✨ - far-future-no-curl
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday-no-curl
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday-missing-curl
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday-missing-curl-no-curl
✨✨✨ SUCCESS ✨✨✨ - moved-curl
✨✨✨ SUCCESS ✨✨✨ - moved-curl-no-curl
✨✨✨ SUCCESS ✨✨✨ - global-protoc
✨✨✨ SUCCESS ✨✨✨ - missing-protocurl-internal
✨✨✨ SUCCESS ✨✨✨ - global-protoc-and-lib
✨✨✨ SUCCESS ✨✨✨ - moved-lib
✨✨✨ SUCCESS ✨✨✨ - missing-protoc
✨✨✨ SUCCESS ✨✨✨ - missing-protoc-global
✨✨✨ SUCCESS ✨✨✨ - echo-filled
✨✨✨ SUCCESS ✨✨✨ - echo-filled-no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-empty
✨✨✨ SUCCESS ✨✨✨ - echo-empty-no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-empty-with-curl-args
✨✨✨ SUCCESS ✨✨✨ - echo-empty-with-curl-args-no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-full
✨✨✨ SUCCESS ✨✨✨ - echo-full-no-curl
✨✨✨ SUCCESS ✨✨✨ - echo-quiet
✨✨✨ SUCCESS ✨✨✨ - echo-quiet-no-curl
✨✨✨ SUCCESS ✨✨✨ - failure-simple
✨✨✨ SUCCESS ✨✨✨ - failure-simple-no-curl
✨✨✨ SUCCESS ✨✨✨ - failure-simple-quiet
✨✨✨ SUCCESS ✨✨✨ - failure-simple-quiet-no-curl
✨✨✨ SUCCESS ✨✨✨ - missing-args
✨✨✨ SUCCESS ✨✨✨ - missing-args-no-curl
✨✨✨ SUCCESS ✨✨✨ - missing-args-partial
✨✨✨ SUCCESS ✨✨✨ - missing-args-partial-no-curl
✨✨✨ SUCCESS ✨✨✨ - help
✨✨✨ SUCCESS ✨✨✨ - help-no-curl
✨✨✨ SUCCESS ✨✨✨ - help-missing-curl
✨✨✨ SUCCESS ✨✨✨ - help-missing-curl-no-curl
✨✨✨ SUCCESS ✨✨✨ - version
✨✨✨ SUCCESS ✨✨✨ - version-no-curl
=== Finished Running ALL Tests ===
Stopping server...
Done.
```
