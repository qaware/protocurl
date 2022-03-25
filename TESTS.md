# Tests

To run the tests:

1. Install `https://stedolan.github.io/jq/` into `test/suite/jq` (executable)
2. Run tests via `./test/suite/test.sh` (bash) from the repository root directory.

### How the tests work

The tests start the local NodeJS based server from `test/servers/server.ts` inside a docker container and send requests
from `test/suite/testcases.json` against the testserver. Each testcase is of the form

```
{
  "filename": "<a filename without spaces and without extension>",
  "args": [
    "<arguments for protocurl>",
    "<These are split into an array to make it easier to write them in the JSON file.>",
    "<All of these array elements will be concatenated with spaces.>"
  ]
}
```

For each testcase, the `args` array will be concatenated and the concatenated string will be given to `protocurl` (via
docker run) as arguments. This happens via `test/suite/run-testcases.sh` - which is dynamically created from the JSON.
This script contains lines of the form

```
testSingleRequest '<filename>' '<args concatenated with spaces>'
```

During the execution of each line in this script, the output will be written into `test/results/$FILENAME-out.txt` -
which will be compared via `diff` to `test/results/$FILENAME-expected.txt`. If both match, then the result is accepted.

**Examples for the inputs, outputs and arguments can hence be found in the test/results directory as well as
test/suite/testcases.json.**

### Adding new tests

To add a test, simply add a new entry into `test/suite/testcases.json` and run the tests. The tests will generate an
empty expected output file and copy the actual output sideby side. You can inspect the actual output and copy it into
the expected-output file when you are happy. ...

### Example tests run

Running the tests might look like this:

```
$ ./test/suite/test.sh
Stopping server...
Removing network servers_default
Network servers_default not found.
Done.
Building protocurl...
sha256:a7618b5140bcf31ec0424715e691e98b4e76221f9af918c66b353216070aa0e8
Done.
Starting server...
Creating network "servers_default" with the default driver
Building server
#1 [internal] load build definition from Dockerfile
#1 sha256:c27871e05b15fda72eae248a90aba327ea5f8779aa6cf8cb715c50962c9a302c
#1 transferring dockerfile: 32B done
#1 DONE 0.0s

#2 [internal] load .dockerignore
#2 sha256:38c9b8dd1dbc8463e0fd4b01a654b65937978e52bfab0565179f29ea8b2e1cc0
#2 transferring context: 2B done
#2 DONE 0.1s

#3 [internal] load metadata for docker.io/library/node:17.7.2
#3 sha256:9615765dad5c925cf043431e40904355dea87cd069996c859d9dd216bf3b5baa
#3 DONE 1.1s

#4 [1/6] FROM docker.io/library/node:17.7.2@sha256:720d77136dc06bbdac28ef5cd13c385e40a2f1bfaaf7340180fc66820cc184e3
#4 sha256:7006c5f31af20e471d38675771d12062efff62f88557525a335068ce1a010473
#4 DONE 0.0s

#6 [internal] load build context
#6 sha256:806ef1c79a28fc659519bb0fab37c5f24203bc469087c7da9c5006cd30ca7766
#6 transferring context: 71.00kB 0.1s done
#6 DONE 0.2s

#5 [2/6] WORKDIR /servers
#5 sha256:d870a498c49a7c64e3a33bb5a502815fe0f510fe210c712d24f1a5c6b7a1e174
#5 CACHED

#7 [3/6] COPY test/servers/package*.json .
#7 sha256:01c2d4f90ac7a8e571c238f871cb62d2e49c1fcc3e2d4868002822c54db818ea
#7 CACHED

#8 [4/6] RUN npm ci
#8 sha256:801037c22dce46a1a44c61d095bb83994925988a35426e41e573c560ef65e5bc
#8 CACHED

#9 [5/6] COPY test/servers/. .
#9 sha256:4947791b8e43235c819b0f0e0e61eeda07139a173424c4ae868913d50496f913
#9 DONE 0.6s

#10 [6/6] COPY test/proto ./proto
#10 sha256:8f9360ed80ffc0d87ddeb7f7e6b4d513d4a3a79db331c498acbe2dab5868229c
#10 DONE 0.1s

#11 exporting to image
#11 sha256:e8c613e07b0b7ff33893b694f7759a10d42e180f2b4dc349fb57dc6b71dcab00
#11 exporting layers
#11 exporting layers 0.5s done
#11 writing image sha256:60a6f227111999081a5592b729b5e51dd2988119168d5b6744754e348737c15c
#11 writing image sha256:60a6f227111999081a5592b729b5e51dd2988119168d5b6744754e348737c15c done
#11 naming to docker.io/library/nodeserver:v1 done
#11 DONE 0.6s

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
Creating protocurl-node-server ...
Creating protocurl-node-server ... done
Done.
Waiting for server to become ready...
Waited 2 seconds already...
=== Test server is ready ===
=== Running ALL Tests ===
✨✨✨ SUCCESS ✨✨✨ - wednesday-is-not-a-happy-day
✨✨✨ SUCCESS ✨✨✨ - other-days-are-happy-days
✨✨✨ SUCCESS ✨✨✨ - no-reason
✨✨✨ SUCCESS ✨✨✨ - far-future
✨✨✨ SUCCESS ✨✨✨ - empty-day-epoch-time-thursday
✨✨✨ SUCCESS ✨✨✨ - echo-filled
✨✨✨ SUCCESS ✨✨✨ - echo-empty
cat: can't open 'response.bin': No such file or directory
✨✨✨ SUCCESS ✨✨✨ - echo-empty-with-curl-args
✨✨✨ SUCCESS ✨✨✨ - echo-full
✨✨✨ SUCCESS ✨✨✨ - failure-simple
✨✨✨ SUCCESS ✨✨✨ - missing-args
✨✨✨ SUCCESS ✨✨✨ - help
=== Finished Running ALL Tests ===
Stopping server...
Stopping protocurl-node-server ...
Stopping protocurl-node-server ... done
Removing protocurl-node-server ...
Removing protocurl-node-server ... done
Removing network servers_default
Done.
```