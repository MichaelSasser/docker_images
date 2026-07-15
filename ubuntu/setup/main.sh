#!/bin/bash
# shellcheck disable=SC2174

set -Eeuo pipefail

#
# APT Preparation (from default.sh)
#
echo '::group::Preparing APT'
echo 'APT::Acquire::Retries "10";' >/etc/apt/apt.conf.d/80-retries
echo 'APT::Get::Assume-Yes "true";' >/etc/apt/apt.conf.d/90assumeyes
apt-get update
apt-get install apt-utils

bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"
echo '::endgroup::'

#
# Environment Setup (from act.sh)
#
echo '::group::Environment Setup'
sed 's|"||g' -i "/etc/environment"

. /etc/os-release

node_arch() {
  case "$(uname -m)" in
  'aarch64') echo 'arm64' ;;
  'x86_64') echo 'x64' ;;
  'armv7l') echo 'armv7l' ;;
  *) exit 1 ;;
  esac
}

ImageOS=ubuntu$(echo "${VERSION_ID}" | cut -d'.' -f 1)
AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ACT_TOOLSDIRECTORY=/opt/acttoolcache
{
  echo "IMAGE_OS=$ImageOS"
  echo "ImageOS=$ImageOS"
  echo "LSB_RELEASE=${VERSION_ID}"
  echo "AGENT_TOOLSDIRECTORY=${AGENT_TOOLSDIRECTORY}"
  echo "RUN_TOOL_CACHE=${AGENT_TOOLSDIRECTORY}"
  echo "DEPLOYMENT_BASEPATH=/opt/runner"
  echo "USER=$(whoami)"
  echo "RUNNER_USER=$(whoami)"
  echo "ACT_TOOLSDIRECTORY=${ACT_TOOLSDIRECTORY}"
} | tee -a "/etc/environment"

mkdir -m 0777 -p "${AGENT_TOOLSDIRECTORY}"
chown -R 1001:1000 "${AGENT_TOOLSDIRECTORY}"
mkdir -m 0777 -p "${ACT_TOOLSDIRECTORY}"
chown -R 1001:1000 "${ACT_TOOLSDIRECTORY}"

mkdir -m 0777 -p /github
chown -R 1001:1000 /github
echo '::endgroup::'

#
# Core Packages (from act.sh)
#
echo "::group::Installing packages"
packages=(
  ssh
  gawk
  curl
  wget
  sudo
  gnupg-agent
  ca-certificates
  software-properties-common
  apt-transport-https
  libyaml-0-2
  zstd
  zip
  unzip
  xz-utils
  python3-pip
  python3-venv
  pipx
)

apt-get -yq update
apt-get -yq install --no-install-recommends --no-install-suggests "${packages[@]}"
echo "::endgroup::"

ln -s "$(which python3)" "/usr/local/bin/python"

#
# Installing jq (from act.sh)
#
echo "::group::Installing jq"
case "$(uname -m)" in
'aarch64') JQ_BINARY_NAME='jq-linux-arm64' ;;
'x86_64') JQ_BINARY_NAME='jq-linux-amd64' ;;
'armv7l') JQ_BINARY_NAME='jq-linux-armhf' ;;
*) exit 1 ;;
esac

echo "Using '${JQ_BINARY_NAME}' as binary name to filter for downloading the jq binary."

JQ_URL=""
retry_count=0
max_retries=3

while [ -z "$JQ_URL" ] && [ "$retry_count" -lt "$max_retries" ]; do
  response=$(curl -sLS --proto '=https' --tlsv1.2 --connect-timeout 60 --retry 5 --retry-all-errors --retry-connrefused 'https://api.github.com/repos/jqlang/jq/releases/latest')
  echo "::group::Installing jq"
  echo "Response from GitHub API: $response" >&2
  echo "::endgroup::"
  if [ -n "$response" ]; then
    JQ_URL=$(echo "$response" | grep browser_download_url | cut -d '"' -f 4 | grep "${JQ_BINARY_NAME}")
  fi

  if [ -z "$JQ_URL" ]; then
    retry_count=$((retry_count + 1))
    echo "Attempt $retry_count failed. Retrying..." >&2
    sleep 5
  fi
done

if [ -z "$JQ_URL" ]; then
  echo "Error: Failed to fetch JQ URL after $max_retries attempts" >&2
  exit 1
fi

echo "Downloading jq from: ${JQ_URL}"

curl -sLS --proto '=https' --tlsv1.2 --connect-timeout 60 --retry 5 --retry-all-errors --retry-connrefused "${JQ_URL}" -o /usr/bin/jq
chown root:root /usr/bin/jq
chmod 755 /usr/bin/jq
echo jq version: "$(/usr/bin/jq --version)"
echo "::endgroup::"

#
# Installing Git + Git LFS (from act.sh)
#
echo "::group::Installing Git"
add-apt-repository ppa:git-core/ppa -y
apt-get update
apt-get install -y --no-install-recommends git

git --version

git config --system --add safe.directory '*'
echo "::endgroup::"

echo "::group::Installing Git LFS"
wget https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh -qO- | bash
apt-get update
apt-get install -y --no-install-recommends git-lfs
echo "::endgroup::"

LSB_OS_VERSION="${VERSION_ID//\./}"
echo "LSB_OS_VERSION=${LSB_OS_VERSION}" | tee -a "/etc/environment"

echo '::group::Downloading Image Generation Scripts'
wget -qO "/imagegeneration/toolset.json" "https://raw.githubusercontent.com/actions/virtual-environments/main/images/ubuntu/toolsets/toolset-${LSB_OS_VERSION}.json" || echo "File not available"
wget -qO "/imagegeneration/LICENSE" "https://raw.githubusercontent.com/actions/virtual-environments/main/LICENSE"
echo '::endgroup::'

#
# SSH Known Hosts (from act.sh)
#
echo '::group::Creating SSH Known Hosts'
echo 'Creating ~/.ssh and adding "github.com" and "ssh.dev.azure.com"'
mkdir -m 0700 -p ~/.ssh
{
  ssh-keyscan github.com
  ssh-keyscan ssh.dev.azure.com
} >>/etc/ssh/ssh_known_hosts
echo '::endgroup::'

#
# Docker / moby (from act.sh)
#
echo '::group::Installing docker, moby-cli, moby-buildx, moby-compose'
if [[ "${VERSION_ID}" == "18.04" ]]; then
  echo "deb https://packages.microsoft.com/ubuntu/${VERSION_ID}/multiarch/prod ${VERSION_CODENAME} main" | tee /etc/apt/sources.list.d/microsoft-prod.list
else
  echo "deb https://packages.microsoft.com/ubuntu/${VERSION_ID}/prod ${VERSION_CODENAME} main" | tee /etc/apt/sources.list.d/microsoft-prod.list
fi
wget -q https://packages.microsoft.com/keys/microsoft.asc
gpg --dearmor <microsoft.asc >/etc/apt/trusted.gpg.d/microsoft.gpg
apt-key add - <microsoft.asc
rm microsoft.asc
apt-get -yq update
apt-get -yq install --no-install-recommends --no-install-suggests moby-cli moby-buildx moby-compose

docker -v
docker buildx version
echo '::endgroup::'

#
# Node.js (from act.sh)
#
echo '::group::Installing Node.JS and tools'
IFS=' ' read -r -a NODE <<<"$NODE_VERSION"
for ver in "${NODE[@]}"; do
  printf "\n\t🐋 Installing Node.JS=%s 🐋\t\n" "${ver}"
  VER=$(curl -sLS --proto '=https' --tlsv1.2 --connect-timeout 60 --retry 5 --retry-all-errors --retry-connrefused https://nodejs.org/download/release/index.json | jq "[.[] | select(.version|test(\"^v${ver}\"))][0].version" -r)
  NODEPATH="${ACT_TOOLSDIRECTORY}/node/${VER:1}/$(node_arch)"
  mkdir -v -m 0777 -p "$NODEPATH"
  wget "https://nodejs.org/download/release/latest-v${ver}.x/node-$VER-linux-$(node_arch).tar.xz" -O "node-$VER-linux-$(node_arch).tar.xz"
  tar -Jxf "node-$VER-linux-$(node_arch).tar.xz" --strip-components=1 -C "$NODEPATH"
  rm "node-$VER-linux-$(node_arch).tar.xz"
  if [[ "${ver}" == "22" ]]; then
    sed "s|^PATH=|PATH=$NODEPATH/bin:|mg" -i /etc/environment
  fi
  export PATH="$NODEPATH/bin:$PATH"

  printf "\n\t🐋 Installed Node.JS 🐋\t\n"
  "${NODEPATH}"/bin/node -v

  printf "\n\t🐋 Installed NPM 🐋\t\n"
  "${NODEPATH}"/bin/npm -v
done
echo '::endgroup::'

#
# yq (from act.sh)
#
echo "::group::Executing Imagegeneration Script yq.sh"
"/imagegeneration/installers/yq.sh"
echo '::endgroup::'

#
# Additional Packages (from default.sh)
#
echo '::group::Install Basic Packages'
apt-get install -y --no-install-recommends tree
echo '::endgroup::'

#
# PATH for local bin (from default.sh)
#
sed "s|PATH=|PATH=/root/.local/bin/:|g" -i /etc/environment

. /etc/environment

#
# Sub-scripts (from default.sh)
#
echo "::group::Executing Sub-scripts"
case "$(uname -m)" in
'aarch64' | 'x86_64')
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

for SCRIPT in "${scripts[@]}"; do
  echo "::group::Executing Script ${SCRIPT}.sh"
  "/imagegeneration/installers/${SCRIPT}.sh"
  echo '::endgroup::'
done
echo '::endgroup::'

. /etc/environment

#
# HashiCorp Stack (from default.sh)
#
echo '::group::Installing Hashicorp Stack'
wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt install --no-install-recommends terraform consul nomad packer

# Hack: We do this to avoid the postinit script which would set the ipc lock
# cap on vault. Generally this is desirable but would be tricky in our CI
# environment. If you want to set the cap, run `vault-setcap` in CI beforehand.
# We also don't want to create a certificate for vault and bake it into the
# image as this would be a security risk. If you need it, you can generate it
# in CI by running `vault-gen-certs`.
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

#
# taplo-cli (from default.sh) [DEPRECATED: use tombi instead]
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
# typst-cli (from default.sh)
#
echo '::group::Installing: typst-cli'
cargo binstall -y --maximum-resolution-timeout 60 --install-path /usr/local/bin typst-cli
echo '::endgroup::'

#
# cmake (from default.sh)
#
echo '::group::Installing: cmake'
apt-get install -y --no-install-recommends cmake
echo '::endgroup::'

#
# Ansible (from default.sh)
#
echo "::group::Installing: Ansible"
apt-get install software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y --no-install-recommends \
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

# [DEPRECATED]: Use ryl instead
echo 'Installing Yamllint'
pip3 install --no-cache-dir --ignore-installed --root-user-action=ignore PyYAML

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
# Astral UV (from default.sh)
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
uv cache clean
echo '::endgroup::'

#
# ryl
#
echo '::group::Installing: ryl'
cargo binstall -y --maximum-resolution-timeout 60 --install-path /usr/local/bin ryl
echo '::endgroup::'

#
# tombi
#
echo '::group::Installing: tombi'
curl --proto '=https' --tlsv1.2 -fsSL https://tombi-toml.github.io/tombi/install.sh | sh -s -- --install-dir /usr/local/bin
echo '::endgroup::'

echo '::group::Installing: just'
cargo binstall -y --maximum-resolution-timeout 60 --install-path /usr/local/bin just
echo '::endgroup::'

#
# Cleanup
#
echo '::group::Cleaning Up Image'
rm -rf "${CARGO_HOME}/registry/*"
apt-get remove -y apt-fast aria2 || true
apt-get clean
rm -rf /imagegeneration
rm -rf /usr/share/man/* /usr/share/doc/*
rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/* /tmp/* || echo 'Failed to delete directories'
echo '::endgroup::'
