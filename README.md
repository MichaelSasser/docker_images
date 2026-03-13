[![Scheduled build](https://github.com/MichaelSasser/docker_images/actions/workflows/build-default.yml/badge.svg?event=schedule)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-default.yml)
[![On-demand build](https://github.com/MichaelSasser/docker_images/actions/workflows/build-default.yml/badge.svg?event=workflow_dispatch)](https://github.com/MichaelSasser/docker_images/actions/workflows/build-default.yml)

<!-- [![Linter](https://github.com/MichaelSasser/docker_images/actions/workflows/lint.yml/badge.svg)](https://github.com/MichaelSasser/docker_images/actions/workflows/lint.yml) -->

# Docker images

The OCI-compatible images created by this repository are intended to be used with
[forgejo-runner](https://code.forgejo.org/forgejo/runner)
(or anything [act](https://github.com/nektos/act) compatible) to power CI/CD
workflows.

> [!IMPORTANT]
> This is a hard fork of
> [catthehacker/docker_images](https://github.com/catthehacker/docker_images)
> which at the time of forking seemed to be abandoned. This fork is not
> intended to be a (drop-in) replacement but rather a continuation of the
> original project with changes that are useful to me.

I initially kept the complex build system from the original project, because
changing it meant a lot of work, with no benefit to the resulting images.
Due to recent issues and timeouts from the external repositories I decided
to put in that work. I first simplified the build system by replacing most of
it with docker buildx, just to make it potentially even more complex in the end.
The advantages we get from this are natively built multi-arch images. Meaning
no qemu emulation layer anymore and therefore quicker turnaround times for
builds.

The initial build process (with the added tools) took around 5-6 hours. On
good days the builds went through successfully, but every so often they
failed due to GitHub free-account limitations.
Optimizing from where the tools come from and how they are installed, the
build times went down to under 2 hours.
The build system rewrite shaves off additional 90% of that, bringing it down
to under 10 minutes for the entire build.

## The Default Image

This image is based on the "Custom", "Rust" and "JavaScript" image from the
original project. Many of the JavaScript tools have been removed and some
Python and Rust tools have been added. The images are based on
Ubuntu 24.04 with Node 22 as the default.

### Images

The images are tagged with timestamps, you can find them all
[here](https://github.com/MichaelSasser/docker_images/pkgs/container/ubuntu).
The "latest" images are listed below. The total file size (extracted) varies
between 5 GB and 6 GB.

#### Stable

- [default-24.04](ghcr.io/MichaelSasser/ubuntu:default-24.04), [default-latest](ghcr.io/MichaelSasser/ubuntu:default-latest)

#### Development

- [default-24.04-dev](ghcr.io/MichaelSasser/ubuntu:default-24.04-dev), [default-latest-dev](ghcr.io/MichaelSasser/ubuntu:default-latest-dev)

### Tools

I am trying to keep the tools up to date. To do this, I have scheduled a
weekly GitHub Action that rebuilds the images to pick up up-to-date tools from
various sources including:

- The latest stable versions as binaries from the original repositories
- Custom package manager repositories
- System package manager
- Building from source

The lists below show most of the tools included in the image.

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
  - Tools: `pre-commit`,
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

- [gh](https://github.com/cli/cli) - The GitHub CLI tool
- [jq](https://github.com/jqlang/jq) - Command-line JSON processor
- [yq](https://github.com/mikefarah/yq) - Command-line YAML processor
- [typst-cli](https://github.com/typst/typst/tree/main/crates/typst-cli) (installed via `binstall`) - A modern typesetting system
- [tea](https://github.com/gitea/tea) - A command line interface for Gitea/Forgejo
- [taplo](https://github.com/tamasfe/taplo) - A fast TOML toolkit

## License

Copyright &copy; 2024 Michael Sasser <info@michaelsasser.org> \
Copyright &copy; 2021 [catthehacker](https://github.com/catthehacker)

Released under the [MIT license](./LICENSE).

### Attribution

This repository contains parts of
[`actions/virtual-environments`][actions/virtual-environments] which is also
licensed under the
[MIT License](https://github.com/actions/virtual-environments/blob/main/LICENSE).

[actions/virtual-environments]: https://github.com/actions/virtual-environments
