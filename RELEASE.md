# Release

We use [GoReleaser](https://goreleaser.com/) to create static binaries and Docker Buildx to build muöti-architecture
images.

The relevant configuration for the release process is in [template.goreleaser.yml](template.goreleaser.yaml)
and [release/source.sh](release/source.sh). See also the [release GitHub Action](.github/workflows/release.yml).

### Developing

To make changes to the release process, first [install GoReleaser](https://goreleaser.com/install/).

You can now inspect the script files and actions used by the GitHub Release Action and change them.

The script files also show alternative commands that can be used, when developing the release process locally.