[![Scheduled build (Ubuntu)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-ubuntu.yml/badge.svg?event=schedule)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-ubuntu.yml)
[![On-demand build (Ubuntu)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-ubuntu.yml/badge.svg?event=workflow_dispatch)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-ubuntu.yml)
[![Linter](https://github.com/MichaelSasser/docker_images/actions/workflows/lint.yml/badge.svg)](https://github.com/MichaelSasser/docker_images/actions/workflows/lint.yml)

# Docker images

The images created by this repository are intended to be used with
[act](https://github.com/nektos/act), to Run your GitHub Actions locally or in
a CI environment like the one Gitea and Forgejo provide.

> [!IMPORTANT]
> This is a hard fork of
> [catthehacker/docker_images](https://github.com/catthehacker/docker_images)
> which at the time of forking seemed to be abandoned. This fork is not
> intended to be a (drop-in) replacement but rather a continuation of the
> original project with changes that are useful to me.

## The Default Image

This image is based on the "Custom", "Rust" and "JavaScript" image from the
original project. Many of the JavaScript tools have been removed and some
Python and Rust tools have been added. The images are based on
Ubuntu 24.04 with Node 22 as the default.

I initially kept the complex build system from the original project, because
changing it meant a lot of work, with no benefit to the resulting images.
Due to recent issues and timeouts from the external repositories I decided
to put in that work. I first simplified the build system using docker buildx,
just to make it potentially even more complex in the end.
The advantages we get from this are natively built multi-arch images. Meaning
no qemu emulation layer anymore and quicker turnaround times for builds.

### Images

#### Stable

- [default-24.04](ghcr.io/MichaelSasser/ubuntu:default-24.04), [default-latest](ghcr.io/MichaelSasser/ubuntu:default-latest)

#### Development

- [default-24.04-dev](ghcr.io/MichaelSasser/ubuntu:default-24.04-dev), [default-latest-dev](ghcr.io/MichaelSasser/ubuntu:default-latest-dev)

### Tools

I am trying to keep the tools (in the images) up to date. Due to
free account limitations, I need to keep the build time relatively short (<5h)
and the size small (only a couple of Gigabytes). To find this balance, I use:

- The latest stable versions as binaries from the original repositories
- Custom package manager repositories
- System package manager
- Building from source

Below are lists of tools included in the images.

> [!NOTE]
> Note, this list may not contain all software included in the image, and the
> may change over time do to varying requirements.

#### Python

- System Python: `python3` with `pip3` installed with the system's package
  manager
  - Installed using `pip`: `toml`, `ansible-lint`, `ansible-navigator`,
    `ansible-builder`, `yamllint`, `PyYAML`
  - Installed using system's package manager: `ansible`, `python3-openssl`,
    `python3-socks`, `python3-docker`, `python3-dockerpty`,
    `python3-ansible-runner`
- `uv`:
  - Installed versions: `3.12`, `3.13` and `3.14`
  - Tools: `poetry` (deprecated), `git-cliff` (deprecated), `pre-commit`,
    and `tox`

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

- `go` ("Golang")

#### C/C++ (or build tools in general)

- System's package manager: `build-essential` `llvm` `clang` `libssl-dev`, `cmake`
- Repo release: `mold` (a modern linker)

#### Additional Tools

- gh (cli/cli) - The GitHub CLI tool
- jq (jqlang/jq) - Command-line JSON processor
- yq (mikefarah/yq) - Command-line YAML processor
- typst-cli (installed via `binstall`) - A modern typesetting system
- tea (gitea/tea) - A command line interface for Gitea/Forgejo
- taplo (tamasfe/taplo) - A fast TOML toolkit

## License

Copyright &copy; 2024 Michael Sasser <info@michaelsasser.org> \
Copyright &copy; 2021 catthehacker

Released under the [MIT license](./LICENSE).

### Attribution

This repository contains parts of
[`actions/virtual-environments`][actions/virtual-environments] which is also
licensed under the
[MIT License](https://github.com/actions/virtual-environments/blob/main/LICENSE).

[actions/virtual-environments]: https://github.com/actions/virtual-environments
