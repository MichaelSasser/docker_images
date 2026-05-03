[![Scheduled build](https://github.com/MichaelSasser/docker_images/actions/workflows/build.yml/badge.svg?event=schedule)](https://github.com/MichaelSasser/docker_images/actions/workflows/build.yml)
[![On-demand build](https://github.com/MichaelSasser/docker_images/actions/workflows/build.yml/badge.svg?event=workflow_dispatch)](https://github.com/MichaelSasser/docker_images/actions/workflows/build.yml)

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

Initially I kept the build process from the original project because
changing it would have meant a lot of work, with no benefit to the resulting images.
Building the images with the added tools took around 5-6 hours, and
had a catastrophically low success rate. Often thanks to GitHub's miserable uptime
after Microsoft took over and free-account limitations resulting from slow builds.

To fix this once and for all, I first optimized from where the tools
are coming from and how they are installed. This brought the build times down
to under 2 hours. Then I rewrote the build process so that multi-arch images are
built on native hardware. (no QEMU emulation layer anymore). This shaved off
another 90% of build time, bringing it down to under 10 minutes for the entire
image.

## Ubuntu

This image is based on the "Custom", "Rust" and "JavaScript" image from the
original project. Many of the JavaScript tools have been removed and some
Python and Rust tools have been added. The images are based on
Ubuntu 24.04 with Node 22 as the default.

### Image

You can find a complete list of images in the
[Packages](https://github.com/MichaelSasser/docker_images/pkgs/container/ubuntu)
section, including images tagged with timestamps.

It is expected that the extracted image is 5 GB to 6 GB in size.

#### Stable

- [ubuntu:24.04](ghcr.io/MichaelSasser/ubuntu:24.04), [ubuntu:latest](ghcr.io/MichaelSasser/ubuntu:latest)

#### Development

- [ubuntu:24.04-dev](ghcr.io/MichaelSasser/ubuntu:24.04-dev), [ubuntu:latest-dev](ghcr.io/MichaelSasser/ubuntu:latest-dev)

### Tools

To keep the tools up-to-date, I have scheduled a weekly build of the images.
The tools are installed from a variety of sources, including:

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
  - Installed versions: `3.13` and `3.14`
  - Tools: `pre-commit`,
    and `tox`

#### Rust

- Toolchains installed using `rustup`:
  - `stable`: contains `rustfmt`, `clippy`
  - `nightly`: contains `rustfmt`, `clippy`, `rustc-codegen-cranelift-preview`
- Targets:
  - `x86_64-unknown-linux-gnu` for `x86` images
  - `aarch64-unknown-linux-gnu` for `aarch64` images
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

#### HashiCorp Stack

- [terraform](https://www.terraform.io/)
- [packer](https://www.packer.io/)
- [vault](https://www.vaultproject.io/) + scripts: `vault-gen-certs` and `vault-setcap`
- [consul](https://www.consul.io/)
- [nomad](https://www.nomadproject.io/)

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
