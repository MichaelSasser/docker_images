#!/bin/bash -e

#set -Eeuxo pipefail

#
# Preparing APT
#
echo '::group::Preparing APT'
# Enable retry logic for apt up to 10 times
echo 'APT::Acquire::Retries "10";' >/etc/apt/apt.conf.d/80-retries
# Configure apt to always assume Y
echo 'APT::Get::Assume-Yes "true";' >/etc/apt/apt.conf.d/90assumeyes
apt-get update
apt-get install apt-utils

# Install apt-fast using quick-install.sh
# https://github.com/ilikenwf/apt-fast
bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"
echo '::endgroup::'

echo '::group::Install Basic Packages'
apt-get install -y tree
echo '::endgroup::'

# echo 'session required pam_limits.so' >>/etc/pam.d/common-session
# echo 'session required pam_limits.so' >>/etc/pam.d/common-session-noninteractive
# echo 'DefaultLimitNOFILE=65536' >>/etc/systemd/system.conf
# echo 'DefaultLimitSTACK=16M:infinity' >>/etc/systemd/system.conf

# {
#   # Raise Number of File Descriptors
#   echo '* soft nofile 65536'
#   echo '* hard nofile 65536'

#   # Double stack size from default 8192KB
#   echo '* soft stack 16384'
#   echo '* hard stack 16384'
# } >>/etc/security/limits.conf

sed "s|PATH=|PATH=/root/.local/bin/:|g" -i /etc/environment

. /etc/environment

case "$(uname -m)" in
'aarch64')
  scripts=(
    basic
    gh
    go
    js
    rust
  )
  ;;
'x86_64')
  scripts=(
    basic
    gh
    go
    js
    rust
  )
  ;;
*) exit 1 ;;
esac

#
# Running Scripts
#
for SCRIPT in "${scripts[@]}"; do
  echo "::group::Executing Script ${SCRIPT}.sh"
  "/imagegeneration/installers/${SCRIPT}.sh"
  echo '::endgroup::'
done

. /etc/environment

#
# Installing: Hashicorp Stack
#
echo '::group::Installing Hashicorp Stack'
wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt install terraform consul nomad packer

# Vault requires some manual steps
apt-get download vault
sudo dpkg --unpack vault*.deb
sudo rm -f /var/lib/dpkg/info/vault.postinst
sudo dpkg --configure vault
sudo apt-get install -yf
sudo rm -f vault*.deb

mkdir --parents /opt/vault/tls
mkdir --parents /opt/vault/data
chown --recursive vault:vault /etc/vault.d
chown --recursive vault:vault /opt/vault
chmod 700 /opt/vault/tls

cat >/usr/bin/vault-gen-certs <<EOF
#!/usr/bin/env bash

openssl req \
  -out /opt/vault/tls/tls.crt \
  -new \
  -keyout /opt/vault/tls/tls.key \
  -newkey rsa:4096 \
  -nodes \
  -sha256 \
  -x509 \
  -subj "/O=HashiCorp/CN=Vault" \
  -days 1095

chmod 600 /opt/vault/tls/tls.crt /opt/vault/tls/tls.key
EOF
chmod +x /usr/bin/vault-gen-certs

cat >/usr/bin/vault-setcap <<EOF
#!/usr/bin/env bash

setcap cap_ipc_lock=+ep /usr/bin/vault
echo "Set capabilities for vault to allow locking memory and preventing swapping"
EOF
chmod +x /usr/bin/vault-setcap
echo '::endgroup::'

echo '::group::Hashicorp Stack Versions'
terraform version
consul version
nomad version
packer version
vault version
echo '::endgroup::'

##
## Installing: tea
##
#echo '::group::Installing tea'
#git clone https://gitea.com/gitea/tea.git
#cd tea
#
#TEA_HASH="$(git rev-list --tags --max-count=1)"
#TEA_VERSION="$(git describe --tags "$TEA_HASH")"
#printf "Installing Gitea tea version: %s\n" "$TEA_VERSION"
#
#git checkout "$TEA_HASH"
#
#go mod vendor
#make
#make install
#
## cleanup
#cd ..
#rm -rf tea
#echo '::endgroup::'

# #
# # Installing: Hub
# #
# echo '::group::Installing Hub'
# apt-get install groff bsdextrautils
#
# git clone \
#   --config transfer.fsckobjects=false \
#   --config receive.fsckobjects=false \
#   --config fetch.fsckobjects=false \
#   https://github.com/github/hub.git
#
# HUB_HASH="$(git rev-list --tags --max-count=1)"
# HUB_VERSION="$(git describe --tags "$HUB_HASH")"
# printf "Installing Github Hub version: %s\n" "$HUB_VERSION"
#
# git checkout "$HUB_HASH"
#
# cd hub
# make install prefix=/usr/local
#
# cd ..
# rm -rf hub
# apt-get uninstall groff bsdextrautils
# apt-get autoremove
# apt-get autoclean
# echo '::endgroup::'

#
# Installing: taplo-cli
#
echo '::group::Installing taplo-cli'
TAPLO_URL="$(curl --proto '=https' --tlsv1.2 -sSf https://api.github.com/repos/tamasfe/taplo/releases/latest | jq -r ".assets.[].browser_download_url | select(. | contains(\"linux-$(uname -m)\"))")"
echo "Downloading taplo from: ${TAPLO_URL}"
curl --proto '=https' --tlsv1.2 -sL "${TAPLO_URL}" | gunzip >/usr/bin/taplo
chmod 755 /usr/bin/taplo
chown root:root /usr/bin/taplo
echo taplo version: "$(/usr/bin/taplo --version)"
echo '::endgroup::'

#
# Installing: typst-cli
#
echo '::group::Installing: typst-cli'
cargo binstall -y --maximum-resolution-timeout 60 typst-cli
echo '::endgroup::'

#
# Installing: cmake
#
echo '::group::Installing: cmake'
apt-get install -y cmake
echo '::endgroup::'

#
# Installing: Ansible
#
echo "::group::Installing: Ansible"
apt-get install software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install \
  ansible \
  python3-openssl \
  python3-socks \
  python3-docker \
  python3-dockerpty \
  python3-ansible-runner \
  python-dev-is-python3 \
  libxml2-dev \
  libxslt1-dev \
  libonig-dev

echo 'Ensure break-system-packages is set for system Python'
python3 -m pip config set --global global.break-system-packages true

echo 'Installing Yamllint'
pip3 install --no-cache-dir --ignore-installed --root-user-action=ignore PyYAML

# Builder should be already installed with ansible-navigator
pip3 install --no-cache-dir --ignore-installed --root-user-action=ignore \
  toml \
  ansible-lint \
  ansible-navigator \
  ansible-builder \
  yamllint

ansible-navigator --version
ansible-builder --version
yamllint --version
echo '::endgroup::'

#
# Installing: Astral UV
#
echo '::group::Installing: Astral UV'
cat >>/etc/environment <<EOF
UV_BREAK_SYSTEM_PACKAGES=true
UV_NO_PROGRESS=true
UV_NO_WRAP=true
UV_INSTALL_DIR="${HOME}/.local/bin"
EOF

. /etc/environment

curl -LsSf https://astral.sh/uv/install.sh | sh

PATH="$UV_INSTALL_DIR:$PATH"

uv python install 3.13 3.14
uv tool update-shell
uv tool install --python-preference=managed pre-commit
uv tool install --python-preference=managed tox
echo '::endgroup::'

#
# Cleanup Image
#
echo '::group::Cleaning Up Image'
rm -rf "${CARGO_HOME}/registry/*"
apt-get clean
rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/* /tmp/* || echo 'Failed to delete directories'
echo '::endgroup::'
