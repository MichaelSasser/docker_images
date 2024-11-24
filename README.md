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
with Node 20 as the default.

### Images

#### Stable

- [default-24.04](ghcr.io/MichaelSasser/ubuntu:default-24.04), [default-latest](ghcr.io/MichaelSasser/ubuntu:default-latest)
- [default-22.04](ghcr.io/MichaelSasser/ubuntu:default-22.04)

#### Development

- [default-24.04-dev](ghcr.io/MichaelSasser/ubuntu:default-24.04-dev), [default-latest-dev](ghcr.io/MichaelSasser/ubuntu:default-latest-dev)
- [default-22.04-dev](ghcr.io/MichaelSasser/ubuntu:default-22.04-dev)

### Software

- **Python**: with the system's Python version, `pip`, `uv` with Python version 3.11, 3.12, 3.13 and 13.13t, `pipx`, `poetry` and `tox`
- **Rust**: `rustup` with the toolchains stable, beta and nightly installed, `rustfmt`, `clippy`, `cbindgen`, `cargo-binstall`, `cargo-audit`, `cargo-outdated`, `cargo-hack`, `cargo-semver-checks`, `rustc-codegen-cranelift-preview`, `cargo-llvm-cov`
- **JavaScript**: `nvm` with `node` LTS versions 16, 18, 20 (default), 22 and `npm`, `pnpm` and `yarn`
- **GO**: `go`
- Additional Tools:
  - Ansible
  - YamlLint
  - git-cliff
  - pre-commit
  - gh
  - jq
  - yq
  - cmake
  - mold
  - typst-cli
  - tea
  - taplo

## License

Copyright &copy; 2024 Michael Sasser <Info@MichaelSasser.org> \
Copyright &copy; 2021 catthehacker

Released under the [MIT license](./LICENSE).

### Attribution

This repository contains parts of
[`actions/virtual-environments`][actions/virtual-environments] which is also
licensed under
[MIT License](https://github.com/actions/virtual-environments/blob/main/LICENSE).

[actions/virtual-environments]: https://github.com/actions/virtual-environments
