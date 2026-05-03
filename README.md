[![Scheduled build](https://github.com/MichaelSasser/docker_images/actions/workflows/build.yml/badge.svg?event=schedule)](https://github.com/MichaelSasser/docker_images/actions/workflows/build.yml)
[![On-demand build](https://github.com/MichaelSasser/docker_images/actions/workflows/build.yml/badge.svg?event=workflow_dispatch)](https://github.com/MichaelSasser/docker_images/actions/workflows/build.yml)

<!-- [![Linter](https://github.com/MichaelSasser/docker_images/actions/workflows/lint.yml/badge.svg)](https://github.com/MichaelSasser/docker_images/actions/workflows/lint.yml) -->

# Docker images

This repository builds `amd64` and `arm64` OCI-compatible multi-arch images
on native hardware, for [act](https://github.com/nektos/act) compatible
runners powering CI/CD workflows. The images contain a set of tools that
are commonly used by our [Forgejo](https://forgejo.org/) workflows. Weekly
builds are scheduled to keep the images and their tools up-to-date.

## Ubuntu

Our general-purpose image, which includes various tools for
building and testing. It is expected that the extracted image is
5 GB to 6 GB in size.

- **Stable**: [ubuntu:24.04](ghcr.io/MichaelSasser/ubuntu:24.04), [ubuntu:latest](ghcr.io/MichaelSasser/ubuntu:latest)
- **Development**: [ubuntu:24.04-dev](ghcr.io/MichaelSasser/ubuntu:24.04-dev), [ubuntu:latest-dev](ghcr.io/MichaelSasser/ubuntu:latest-dev)

### Tools

The tools are installed from various sources, including:

- The latest stable versions as binaries from the original repositories
- Custom package manager repositories
- System package manager
- Building from source

The lists below (click to unfold) show most of the tools included in the image.

<!-- Rust -->
<details>
  <summary>Rust</summary>

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

</details>

<!-- Python -->
<details>
  <summary>Python</summary>

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

</details>

<!-- Node -->
<details>
  <summary>Node</summary>

- Versions: `18`, `20`, `22` (default) and `24`
- Tools: `nvm`, `npm`, `pnpm` and `yarn`

</details>

<!-- Go -->
<details>
  <summary>Go</summary>

- `go` ("Golang")

</details>

<!-- C/C++ -->
<details>
  <summary>C/C++ (and build tools in general)</summary>

- System's package manager: `build-essential` `llvm` `clang` `libssl-dev`, `cmake`
- Repo release: `mold` (a modern linker)

</details>

<!-- HashiCorp -->
<details>
  <summary>HashiCorp Stack</summary>

- [terraform](https://www.terraform.io/)
- [packer](https://www.packer.io/)
- [vault](https://www.vaultproject.io/) + scripts: `vault-gen-certs` and `vault-setcap`
- [consul](https://www.consul.io/)
- [nomad](https://www.nomadproject.io/)

</details>

<!-- Misc -->
<details>
  <summary>Misc</summary>

- [gh](https://github.com/cli/cli) - The GitHub CLI tool
- [jq](https://github.com/jqlang/jq) - Command-line JSON processor
- [yq](https://github.com/mikefarah/yq) - Command-line YAML processor
- [typst-cli](https://github.com/typst/typst/tree/main/crates/typst-cli) (installed via `binstall`) - A modern typesetting system
- [tea](https://github.com/gitea/tea) - A command line interface for Gitea/Forgejo
- [taplo](https://github.com/tamasfe/taplo) - A fast TOML toolkit

</details>

## License

Copyright &copy; 2024 Michael Sasser <info@michaelsasser.org> \
Copyright &copy; 2021 [catthehacker](https://github.com/catthehacker)

Released under the [MIT license](./LICENSE).

### Attribution

This repository is hard fork of
[catthehacker/docker_images](https://github.com/catthehacker/docker_images).
It contains parts of
[`actions/virtual-environments`][actions/virtual-environments] which is also
licensed under the
[MIT License](https://github.com/actions/virtual-environments/blob/main/LICENSE).

[actions/virtual-environments]: https://github.com/actions/virtual-environments
