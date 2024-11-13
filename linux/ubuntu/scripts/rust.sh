#!/bin/bash
# shellcheck disable=SC1091

set -Eeuxo pipefail

. /etc/environment
. /imagegeneration/installers/helpers/os.sh

export RUSTUP_HOME=/usr/share/rust/.rustup
export CARGO_HOME=/usr/share/rust/.cargo

printf "\n\t🐋 Installing dependencies 🐋\t\n"
apt-get -yq update
apt-get -yq install build-essential llvm libssl-dev

printf "\n\t🐋 Installing Rust 🐋\t\n"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain=stable --profile=minimal

source "${CARGO_HOME}/env"

rustup toolchain install nightly beta
rustup component add rustfmt clippy

printf "\n\t🐋 Installing cargo-binstall 🐋\t\n"
# Pinned to commit-hash for latest release v1.10.12 to prevent accidental problems
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/dae59123ebcd0833a1b28f1af21ab08352d3965b/install-from-binstall-release.sh | bash

cargo binstall -y bindgen-cli cbindgen cargo-audit cargo-outdated cargo-hack cargo-semver-checks

chmod -R 777 "$(dirname "${RUSTUP_HOME}")"

# cleanup
rm -rf "${CARGO_HOME}/registry/*"

sed "s|PATH=|PATH=${CARGO_HOME}/bin:|g" -i /etc/environment

cd /root
ln -sf "${CARGO_HOME}" .cargo
ln -sf "${RUSTUP_HOME}" .rustup
{
  echo "RUSTUP_HOME=${RUSTUP_HOME}"
  echo "CARGO_HOME=${CARGO_HOME}"
} | tee -a /etc/environment

printf "\n\t🐋 Installed RUSTUP 🐋\t\n"
rustup -V

printf "\n\t🐋 Installed CARGO 🐋\t\n"
cargo -V

printf "\n\t🐋 Installed RUSTC 🐋\t\n"
rustc -V

printf "\n\t🐋 Cleaning image 🐋\t\n"
apt-get clean
rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/* /tmp/* || echo 'Failed to delete directories'

printf "\n\t🐋 Cleaned up image 🐋\t\n"
