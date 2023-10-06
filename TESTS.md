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
This happens via `test/suite/testcases.run` - which is dynamically created from the JSON. This script contains lines
of the form

```
testSingleSpec '<filename>' '<args concatenated with spaces>' '<bash statements>' 'some-arg-for-one-scenario' 'some-arg-for-another-scenario'
```

During the execution of each line in this script (after escaping and parallelisation with xargs), the output will be written into `test/results/$FILENAME-out.txt` -
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
Populating cache...
Established Protobuf version 24.4
Using cache...
Established go version 1.21.1
Using cache...
Established Goreleaser version v1.21.2
Using cache...
Established Latest released protoCURL version v1.7.0
Variables: VERSION=1.8.0-rc-dev, VVERSION=v1.8.0-rc-dev, SNAPSHOT=true, BUILD_ARCH=amd64, PROTO_VERSION=24.4
Stopping server...
Done.
Building protocurl:latest ...
sha256:cc3be835f4e8a05cc0083bdfccc2c5c09854f4dc585bdedcb780d0bf582c5c9c
Done.
Building test image variant of protocurl including additonal executables ...
[+] Building 0.3s (15/15) FINISHED                                                                                                                     docker:default
 => [internal] load build definition from Dockerfile                                                                                                             0.0s
 => => transferring dockerfile: 608B                                                                                                                             0.0s
 => [internal] load .dockerignore                                                                                                                                0.0s
 => => transferring context: 78B                                                                                                                                 0.0s
 => [internal] load metadata for docker.io/library/debian:11-slim                                                                                                0.2s
 => [internal] load metadata for docker.io/library/protocurl:latest                                                                                              0.0s
 => [builder 1/2] FROM docker.io/library/debian:11-slim@sha256:c618be84fc82aa8ba203abbb07218410b0f5b3c7cb6b4e7248fda7785d4f9946                                  0.0s
 => [final 1/8] FROM docker.io/library/protocurl:latest                                                                                                          0.0s
 => CACHED [builder 2/2] RUN apt-get update && apt-get install -y inotify-tools procps                                                                           0.0s
 => CACHED [final 2/8] COPY --from=builder /bin/* /bin/                                                                                                          0.0s
 => CACHED [final 3/8] COPY --from=builder /usr/bin/* /usr/bin/                                                                                                  0.0s
 => CACHED [final 4/8] COPY --from=builder /lib/*-linux-gnu /lib/x86_64-linux-gnu/                                                                               0.0s
 => CACHED [final 5/8] COPY --from=builder /lib/*-linux-gnu /lib/aarch_64-linux-gnu/                                                                             0.0s
 => CACHED [final 6/8] COPY --from=builder /usr/lib/*-linux-gnu /usr/lib/x86_64-linux-gnu/                                                                       0.0s
 => CACHED [final 7/8] COPY --from=builder /usr/lib/*-linux-gnu /usr/lib/aarch_64-linux-gnu/                                                                     0.0s
 => CACHED [final 8/8] COPY --from=builder /lib64*/ld-linux-*.so.2 /lib64/                                                                                       0.0s
 => exporting to image                                                                                                                                           0.0s
 => => exporting layers                                                                                                                                          0.0s
 => => writing image sha256:1c56da99fb8a4e5cc3303bb9b4170254e6e962758c96fcf7718a6dfc08a3c999                                                                     0.0s
 => => naming to docker.io/library/protocurl:latest-test                                                                                                         0.0s
Done.
Starting server...
Done.
Waiting for server to become ready...
Waited 2 seconds already...
Waited 3 seconds already...
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
✨✨✨ SUCCESS ✨✨✨ - failure-simple-quiet-no-curl
✨✨✨ SUCCESS ✨✨✨ - failure-simple-quiet--X_GET
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
