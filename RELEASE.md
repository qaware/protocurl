# Release

We use [GoReleaser](https://goreleaser.com/) to create static binaries. They are released via GitHub Action
here (<todo>).

The relevant configuration is in [template.goreleaser.yml](template.goreleaser.yaml).

### Setup

To make changes to the release process, first [install GoReleaser](https://goreleaser.com/install/).

### Check configuration file

```
goreleaser check
```

### Local Release during Development

```
goreleaser release --snapshot --rm-dist
```