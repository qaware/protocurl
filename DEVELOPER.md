# Developer

Almost all development, except for the execution of `test/suite/test.sh` is based on docker. For the execution of the
test script, one can use native bash or attempt to use WSL and variations on Windows.

As for script utilities, one needs `bash`, `jq`, `unzip` and `curl`.

## Test server

When new dependencies are needed for the test server, the following command enables one to start a shell in the test
server.

```
docker run -v "$PWD/test/servers:/servers" -it nodeserver:v1 /bin/bash
```

Now it's possible to add new dependencies via `npm install <new-package>`

## Updating Docs after changes

Generate the main docs (.md files etc.) in bash/WSL via `doc/generate-docs.sh <absolute-path-to-protocurl-repository>`.

Once a pull request is ready, run this to generate updated docs.
