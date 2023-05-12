# Scripts

Shell scripts and whatnot.

## Setup

Intended for Linux. WSL works fine.

```sh
git clone https://github.com/acrois/scripts ~/scripts
~/scripts/config.sh
```

[config.sh](./config.sh) adds a call to `source` to the end of your `~/.profile` that points to the [config/.profile](./config/.profile) from `~/scripts/` which sets the `$PATH` environmental variable to include `~/scripts/shell` so that you may clone and call shell scripts.

## Version Control

Scripts for making managing version control systems easier (read: automatic).

### Git Calendar Versioning

[shell/calver.sh](./shell/calver.sh) - Utility for automatically tagging git repositories using CalVer.

#### Install

Just want to install this one? The following will probably work for you:

```sh
sudo curl -o /usr/local/bin/calver.sh https://raw.githubusercontent.com/acrois/scripts/HEAD/shell/calver.sh
sudo chmod +x /usr/local/bin/calver.sh
```

#### Usage

```
Usage:
        calver.sh --version="2023.19.03" --variant="dev" --revision="10"
        calver.sh --from-date="2023-05-10" --variant="dev" --revision="10"

Output tags:
        Revision:  2023.19.03-dev.10
        Variant:   2023.19.03-dev
        Calendar:  2023.19.03

Flags:
        --format            - date format, defaults to %Y.%V.%w according to `man date`
        --version           - version to release
        --from-date         - date to base version off of
        --auto              - automatically creates variants based on branch name.
                                if on main, master, or trunk it is "".
                                if there is no branch, it is "detached".
        --variant           - adds a variant tag e.g
        --revision          - adds a revision incrementer after the variant e.g 2023.19.03-dev.10
        --apply             - disable dry run and do it for real
        --push              - push after applying
        --show              - show version tag (values: calendar, variant, revision)
        --v                 - verbose output (`set -x`)
        --help              - prints this useful information
```
