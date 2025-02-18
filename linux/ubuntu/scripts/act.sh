#!/bin/bash
# shellcheck disable=SC2174

set -Eeuxo pipefail

#
# Installing ACT
#
echo '::group::Installing ACT'
# Remove '"' so it can be sourced by sh/bash
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

packages=(
  ssh
  gawk
  curl
  jq
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

#
# Installing Packages
#
echo "::group::Installing packages"
apt-get -yq update
apt-get -yq install --no-install-recommends --no-install-suggests "${packages[@]}"
echo "::endgroup::"

ln -s "$(which python3)" "/usr/local/bin/python"

#
# installing Git
#
echo "::group::Installing Git"
add-apt-repository ppa:git-core/ppa -y
apt-get update
apt-get install -y git

git --version

git config --system --add safe.directory '*'
echo "::endgroup::"

#
# Installing Git LFS
#
echo "::group::Installing Git LFS"
wget https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh -qO- | bash
apt-get update
apt-get install -y git-lfs
echo "::endgroup::"

LSB_OS_VERSION="${VERSION_ID//\./}"
echo "LSB_OS_VERSION=${LSB_OS_VERSION}" | tee -a "/etc/environment"

echo '::group::Downloading Image Generation Scripts'
wget -qO "/imagegeneration/toolset.json" "https://raw.githubusercontent.com/actions/virtual-environments/main/images/ubuntu/toolsets/toolset-${LSB_OS_VERSION}.json" || echo "File not available"
wget -qO "/imagegeneration/LICENSE" "https://raw.githubusercontent.com/actions/virtual-environments/main/LICENSE"
echo '::endgroup::'

#
# Installing jq for x86_64
#
if [ "$(uname -m)" = x86_64 ]; then
  echo '::group::Installing jq for x86_64'
  wget -qO "/usr/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
  chmod +x "/usr/bin/jq"
  echo '::endgroup::'
fi

#
# Creating SSH Known Hosts
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
# Installing docker, moby-cli, moby-buildx, moby-compose
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
# Installing Node.JS and tools
#
echo '::group::Installing Node.JS and tools'
IFS=' ' read -r -a NODE <<<"$NODE_VERSION"
for ver in "${NODE[@]}"; do
  printf "\n\t🐋 Installing Node.JS=%s 🐋\t\n" "${ver}"
  VER=$(curl https://nodejs.org/download/release/index.json | jq "[.[] | select(.version|test(\"^v${ver}\"))][0].version" -r)
  NODEPATH="${ACT_TOOLSDIRECTORY}/node/${VER:1}/$(node_arch)"
  mkdir -v -m 0777 -p "$NODEPATH"
  wget "https://nodejs.org/download/release/latest-v${ver}.x/node-$VER-linux-$(node_arch).tar.xz" -O "node-$VER-linux-$(node_arch).tar.xz"
  tar -Jxf "node-$VER-linux-$(node_arch).tar.xz" --strip-components=1 -C "$NODEPATH"
  rm "node-$VER-linux-$(node_arch).tar.xz"
  if [[ "${ver}" == "20" ]]; then # make this version the default (latest LTS)
    sed "s|^PATH=|PATH=$NODEPATH/bin:|mg" -i /etc/environment
  fi
  export PATH="$NODEPATH/bin:$PATH"

  printf "\n\t🐋 Installed Node.JS 🐋\t\n"
  "${NODEPATH}"/bin/node -v

  printf "\n\t🐋 Installed NPM 🐋\t\n"
  "${NODEPATH}"/bin/npm -v
done
echo '::endgroup::'

case "$(uname -m)" in
'aarch64')
  scripts=(
    yq
  )
  ;;
'x86_64')
  scripts=(
    yq
  )
  ;;
'armv7l')
  scripts=(
    yq
  )
  ;;
*) exit 1 ;;
esac

#
# Running Imagegeneration Scripts
#
for SCRIPT in "${scripts[@]}"; do
  echo "::group::Executing Imagegeneration Script ${SCRIPT}.sh"
  "/imagegeneration/installers/${SCRIPT}.sh"
  echo '::endgroup::'
done

echo "::group::Cleaning Up Image"
apt-get clean
rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/* /tmp/* || echo 'Failed to delete directories'
echo '::endgroup::'

echo '::endgroup::'
