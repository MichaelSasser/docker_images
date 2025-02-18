#!/bin/bash
# shellcheck disable=SC1091

set -Eeuxo pipefail

. /etc/environment
. /imagegeneration/installers/helpers/os.sh

export RUSTUP_HOME=/usr/share/rust/.rustup
export CARGO_HOME=/usr/share/rust/.cargo

echo '::group::Installing Dependencies'
apt-get -yq update
apt-get -yq install build-essential llvm clang libssl-dev
echo '::endgroup::'

echo '::group::Installing Rust'
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain=stable --profile=minimal
echo '::endgroup::'

source "${CARGO_HOME}/env"

echo '::group::Installing Toolchains and Components'
rustup toolchain install nightly beta
rustup component add --toolchain stable rustfmt clippy # Shouldn't be needed
rustup component add --toolchain nightly rustfmt clippy rustc-codegen-cranelift-preview
rustup component add --toolchain beta rustfmt clippy
echo '::endgroup::'

echo '::group::Installing Cargo Binstall'
# Pinned to commit-hash for latest release v1.10.12 to prevent accidental problems
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/dae59123ebcd0833a1b28f1af21ab08352d3965b/install-from-binstall-release.sh | bash
echo '::endgroup::'

echo 'group::Installing Tools with Cargo Binstall'
cargo binstall -y bindgen-cli cbindgen cargo-audit cargo-outdated cargo-hack cargo-semver-checks cargo-llvm-cov

chmod -R 777 "$(dirname "${RUSTUP_HOME}")"
echo '::endgroup::'

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

echo '::group::Version Rustup'
rustup -V
echo '::endgroup::'

echo '::group::Version Cargo'
cargo -V
echo '::endgroup::'

echo '::group::Version Rustc'
rustc -V
echo '::endgroup::'

echo '::group::Installing Mold Linker'
git clone --branch stable https://github.com/rui314/mold.git
cd mold

MOLD_HASH="$(git rev-list --tags --max-count=1)"
MOLD_VERSION="$(git describe --tags "$MOLD_HASH")"
printf "Installing mold version: %s\n" "$MOLD_VERSION"

git checkout "$MOLD_HASH"

mkdir -p build
cd build

../install-build-deps.sh

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=c++ -DCMAKE_INSTALL_PREFIX=/usr -B build ..
cmake --build build -j$(nproc)
sudo cmake --build build --target install

# cleanup
rm -rf /root/mold
echo '::endgroup::'

echo '::group::Cleaning Up Image'
apt-get clean
rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/* /tmp/* || echo 'Failed to delete directories'
echo '::endgroup::'
