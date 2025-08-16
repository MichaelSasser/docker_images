[![Scheduled build (Ubuntu)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-ubuntu.yml/badge.svg?event=schedule)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-ubuntu.yml)
[![On-demand build (Ubuntu)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-ubuntu.yml/badge.svg?event=workflow_dispatch)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-ubuntu.yml)
[![Linter](https://github.com/MichaelSasser/docker_images/actions/workflows/lint.yml/badge.svg)](https://github.com/MichaelSasser/docker_images/actions/workflows/lint.yml)

# Docker images

The images created by this repository are intended to be used with
[act](https://github.com/nektos/act), to Run your GitHub Actions "locally".

> [!IMPORTANT]
> This is a hard fork of
> [catthehacker/docker_images](https://github.com/catthehacker/docker_images)
> which at the time of forking seemed to be abandoned. This fork is not
> intended to be a (drop-in) replacement but rather a (temporary?)
> continuation of the original project with changes. Instead of having
> multiple image variants for different use cases, this fork will only have
> a single variant for now, with a default set of tools and packages that
> are useful to me and my workflows on my Forgejo instance.

## The Default Images

At present, this is the only image available. It is based on the Custom,
Rust and JavaScript image from the original project with some modifications.
Many of the available JavaScript tools have been removed and some Python
tools have been added. The latest image is now based on Ubuntu 24.04
with Node 22 as the default.

### Images

#### Stable

- [default-24.04](ghcr.io/MichaelSasser/ubuntu:default-24.04), [default-latest](ghcr.io/MichaelSasser/ubuntu:default-latest)

#### Development

- [default-24.04-dev](ghcr.io/MichaelSasser/ubuntu:default-24.04-dev), [default-latest-dev](ghcr.io/MichaelSasser/ubuntu:default-latest-dev)

### Software

We tries as much as possible to keep the software in the images up to date.
Therefore we either often get the latest stable version as binary from the
repo, add custom repositories or use the system package manager to install
them or build them from source. The following is a list of the software we
include in the image.

> [!NOTE]
> Note, this list may not contain all software included in the image, and the
> list may change over time.

#### Python

- System Python: `python3` with `pip3` installed from the system package
  manager
  - Installed using `pip`: `toml`, `ansible-lint`, `ansible-navigator`,
    `ansible-builder`, `yamllint`, `PyYAML`
  - Installed using system's package manager: `ansible`, `python3-openssl`,
    `python3-socks`, `python3-docker`, `python3-dockerpty`,
    `python3-ansible-runner`
- `uv`:
  - Installed versions: `3.11`, `3.12` and `3.13`
  - Tools: `poetry`, `git-cliff` (deprecated), `pre-commit`, and `tox`

#### Rust

- Toolchains installed using `rustup`:
  - `stable`: contains `rustfmt`, `clippy`
  - `nightly`: contains `rustfmt`, `clippy`, `rustc-codegen-cranelift-preview`
- Tools:
  - `binstall`
    - `bindgen-cli`, `cbindgen`, `cargo-audit`, `cargo-outdated`,
      `cargo-hack`, `cargo-semver-checks`, `cargo-llvm-cov`

#### Node

- Versions: `18`, `20`, `22` (default) and `24`
- Tools: `nvm`, `npm`, `pnpm` and `yarn`

#### Go

- `go`

#### C/C++ (or build tools in general)

- System's package manager: `build-essential` `llvm` `clang` `libssl-dev`, `cmake`
- Repo release: `mold`

#### Additional Tools

- gh (cli/cli)
- jq (jqlang/jq)
- yq (mikefarah/yq)
- typst-cli (installed via `binstall`)
- tea (gitea/tea)
- taplo (tamasfe/taplo)

## License

Copyright &copy; 2024 Michael Sasser <Info@MichaelSasser.org> \
Copyright &copy; 2021 catthehacker

Released under the [MIT license](./LICENSE).

### Attribution

This repository contains parts of
[`actions/virtual-environments`][actions/virtual-environments] which is also
licensed under the
[MIT License](https://github.com/actions/virtual-environments/blob/main/LICENSE).

[actions/virtual-environments]: https://github.com/actions/virtual-environments
