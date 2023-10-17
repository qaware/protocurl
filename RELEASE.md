# Release

We use [GoReleaser](https://goreleaser.com/) to create static binaries and Docker Buildx to build multi-architecture
images.

The relevant configuration for the release process is in [template.goreleaser.yml](template.goreleaser.yaml)
and [release/source.sh](release/source.sh). It **automatically** fetches the **latest** Go, Goreleaser and Protobuf
versions via GitHub API.

See also the [.github/workflows/release.yml](.github/workflows/release.yml).

## Development

To make changes to the release process, first [install GoReleaser](https://goreleaser.com/install/).

You can now inspect the script files and actions used by the GitHub Release Action and change them.

The script files also show alternative commands that can be used, when developing the release process locally.

## Release Process

The release process works by manually running the **Release** workflow on GitHub. There one needs to provide the
version (e.g. 1.2.3 or 1.2.3-next) for the new release. The corresponding commit will be tagged correspondingly (e.g.
v1.2.3). A new release should first be a release candidate, e.g. `1.2.3-rc` - and only when the workflow passes for the
release candidate - then the same commit should be properly released as `1.2.3`.

The release process works like this:

* the [Google Protobuf Binaries](https://github.com/protocolbuffers/protobuf/releases) for the specified PROTOC_VERSION
  are downloaded
* Goreleaser is used to cross-compile and build binaries as well as create the archives for the GitHub release and the
  doker images
* [Docker Buildx](https://docs.docker.com/engine/reference/commandline/buildx/) is used to build multi-architecture
  images and push them to [qaware/protocurl](https://hub.docker.com/r/qaware/protocurl)
  * their Dockerfile is generated via [release/40-generate-Dockerfile.sh](release/40-generate-Dockerfile.sh)
  * There is a [hack](release/final.Dockerfile), when copying the proper lib files via multi-stage builds and build args into the [distroless cc](https://github.com/GoogleContainerTools/distroless/tree/main/cc) image.
* Native tests for multiple platforms are run. If these tests fail then the release candidate needs to be fixed.
  * This should only happen for release candidates - as proper releases should only be created once a release candidate
    passes all tests.

After fixing the code and the tests, a release candidate's tag can be overwritten by setting the option `force`
to `force-reuse-tag` when invoking the workflow. This should only be used when a release candidate is released again
should be overwritten.


## Updating Dependencies

Most dependencies are automatically checked for updates via [Dependabot](.github/dependabot.yml).

The remaining dependencies cannot be managed via Dependabot, because they are manually retrieved
during release via [0-get-latest-dependencies-versions.sh](./release/0-get-latest-dependencies-versions.sh).
* Hence, a weekly GitHub Action [check-manual-dependencies](.github/workflows/check-manual-dependencies.yml) checks whether the committed [versions.txt](release/versions.txt) matches the actual latest versions.
* If there is a new version, then the build creates a pull request with the new versions and the CI automatically runs it.
* The pull request is [automatically merged](https://github.com/peter-evans/enable-pull-request-automerge), when the CI tests pass.
  * We need to use a [SSH deploy key](https://github.com/peter-evans/create-pull-request/blob/main/docs/concepts-guidelines.md#push-using-ssh-deploy-keys), as otherwise the automatic CI tests wouldn't be triggered. We created a secret `NEW_PULL_REQUEST_KEY` and it's corresponding deploy key for that.
  * For the pull request to be auto-merged, we need to have a branch protection rule.
    We [created one](https://github.com/qaware/protocurl/settings/branches) where the `test` workflow must pass as a status check before a pull request can be merged.
