# Developer

For development it is recommanded to use the a bash-like Terminal either natively (Linux, Mac) or via MinGW on Windows.

**Preconditions**

* As for script utilities, one needs `bash`, `jq`, `zip`, `unzip` and `curl`.
* One also needs to download the protoc binaries for the local development via `release/0-get-protoc-binaries.sh`.

For development the [local.Dockerfile](src/local.Dockerfile) is used. To build the image simply
run `source test/suite/setup.sh` and then `buildProtocurl`

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

## Release

See [RELEASE.md](RELEASE.md)