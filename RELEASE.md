# Release

We use [GoReleaser](https://goreleaser.com/) to create static binaries and Docker Buildx to build muöti-architecture
images.

The relevant configuration for the release process is in [template.goreleaser.yml](template.goreleaser.yaml)
and [release/source.sh](release/source.sh). See also the [release GitHub Action](.github/workflows/release.yml).

### Developing

To make changes to the release process, first [install GoReleaser](https://goreleaser.com/install/).

You can now inspect the script files and actions used by the GitHub Release Action and change them.

The script files also show alternative commands that can be used, when developing the release process locally.

## Release Process

The release process works by manually running the **Release** workflow on GitHub. There one needs to provide the
version (e.g. 1.2.3 or 1.2.3-next) for the new release. The corresponding commit will be tagged correspondingly (e.g.
v1.2.3). The release process works like this:

* the [Google Protobuf Binaries](https://github.com/protocolbuffers/protobuf/releases) for the specified PROTOC_VERSION
  are downloaded
* Goreleaser is used to cross-compile and build binaries as well as create the archives for the GitHub release and the
  doker images
* [Docker Buildx](https://docs.docker.com/engine/reference/commandline/buildx/) is used to build multi-architecture
  images and push them to [qaware/protocurl](https://hub.docker.com/r/qaware/protocurl)
