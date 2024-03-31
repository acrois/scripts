# Scripts

[![Build Image](https://github.com/acrois/scripts/actions/workflows/build.yaml/badge.svg)](https://github.com/acrois/scripts/actions/workflows/build.yaml) [![CalVer Tagging](https://github.com/acrois/scripts/actions/workflows/calver.yaml/badge.svg)](https://github.com/acrois/scripts/actions/workflows/calver.yaml)

Shell scripts and whatnot.

## Docker Usage

Can be run from anywhere, based on the latest Alpine image.

```sh
docker run --rm ghcr.io/acrois/scripts:latest calver --help
```

## Setup

Intended for Linux-based environments. WSL works fine. Windows will probably not work due to symlinks.

```sh
git clone --recurse-submodules https://github.com/acrois/scripts ~/scripts
~/scripts/config.sh
```

[config.sh](./config.sh) adds a call to `source` to the end of your `~/.profile` that points to the [config/.profile](./config/.profile) from `~/scripts/` which sets the `$PATH` environmental variable to include `~/scripts/shell` so that you may clone and call shell scripts.

## Version Control

Scripts for making managing version control systems easier (read: automatic).

### Git Calendar Versioning

[calver.sh](https://github.com/acrois/calver) - Utility for automatically tagging git repositories using CalVer.

For full documentaiton, please see the [calver.sh](https://github.com/acrois/calver) readme.

### Git Branch Archival

[shell/bclean.sh](./shell/bclean.sh) - Utility for archiving (deleting) old branches while preserving history using tags.

#### Install

Just want to install this one? The following will probably work for you:

```sh
sudo curl -o /usr/local/bin/bclean.sh https://raw.githubusercontent.com/acrois/scripts/HEAD/shell/bclean.sh
sudo chmod +x /usr/local/bin/bclean.sh
```

#### Usage

[//]: # (using bclean.sh)
```
Usage:
        bclean.sh --test --push --apply

Flags:
        --keep [branch]     - keep a branch by name
        --path [path]       - path to git repository
        --test              - creates a git repository to self-test the cleanup procedure
        --apply             - disable dry run and do it for real
        --push, -p          - push after applying
        --v                 - verbose output (`set -x`)
        --help              - prints this useful information
```
[//]: # (used bclean.sh)
