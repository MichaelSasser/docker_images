#!/bin/bash -e

#set -Eeuxo pipefail

printf "\n\t🔧 Preparing apt 🔧\t\n"

# Enable retry logic for apt up to 10 times
echo 'APT::Acquire::Retries "10";' >/etc/apt/apt.conf.d/80-retries

# Configure apt to always assume Y
echo 'APT::Get::Assume-Yes "true";' >/etc/apt/apt.conf.d/90assumeyes

apt-get update
apt-get install apt-utils

# Install apt-fast using quick-install.sh
# https://github.com/ilikenwf/apt-fast
bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"

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

for SCRIPT in "${scripts[@]}"; do
  printf "\n\t🧨 Executing %s.sh 🧨\t\n" "${SCRIPT}"
  "/imagegeneration/installers/${SCRIPT}.sh"
done

. /etc/environment

printf "\n\t🐋 Installing typst-cli 🐋\t\n"
cargo binstall -y typst-cli

printf "\n\t🐋 Installing cmake 🐋\t\n"
apt-get install -y cmake

printf "\n\t🐋 Installing Ansible 🐋\t\n"
apt-get install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y \
  ansible \
  python3-openssl \
  python3-socks \
  python3-docker \
  python3-dockerpty

printf "\n\t🐋 Installing Yamllint 🐋\t\n"
apt-get install -y yamllint
pip3 install --no-cache-dir ansible-lint

printf "\n\t🐋 Installing Astral UV 🐋\t\n"
cat >>/etc/environment <<EOF
UV_BREAK_SYSTEM_PACKAGES=true
UV_NO_PROGRESS=true
UV_NO_WRAP=true
UV_INSTALL_DIR="${HOME}/.local/bin"
EOF

. /etc/environment

curl -LsSf https://astral.sh/uv/install.sh | sh

PATH="$UV_INSTALL_DIR:$PATH"

uv python install 3.10 3.11 3.12 3.13 3.13t
uv tool update-shell
uv tool install --python-preference=managed poetry git-cliff pre-commit tox

printf "\n\t🐋 Cleaning image 🐋\t\n"
rm -rf "${CARGO_HOME}/registry/*"
apt-get clean
rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/* /tmp/* || echo 'Failed to delete directories'
printf "\n\t🐋 Cleaned up image 🐋\t\n"
