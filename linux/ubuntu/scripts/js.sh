#!/bin/bash
# shellcheck disable=SC1091,SC2174,SC2016

set -Eeuo pipefail

. /etc/environment

#
# Installing NVM Tools
#
echo '::group::Installing NVM Tools'
VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.tag_name')
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$VERSION/install.sh" | bash
export NVM_DIR=$HOME/.nvm
echo "NVM_DIR=$HOME/.nvm" | tee -a /etc/environment

# Expressions don't expand in single quotes, use double quotes for that.shellcheck(SC2016)
# shellcheck disable=SC2016
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' | tee -a /etc/skel/.bash_profile

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

printf "\n\t🐋 Installed NVM 🐋\t\n"
nvm --version

# Node 18, 20, 22 are already installed in act.sh (base image)
versions=("24")
JSON=$(wget -qO- https://nodejs.org/download/release/index.json | jq --compact-output)

ARCH=$(uname -m)
if [ "$ARCH" = x86_64 ]; then ARCH=x64; fi
if [ "$ARCH" = aarch64 ]; then ARCH=arm64; fi

for V in "${versions[@]}"; do
  printf "\n\t🐋 Installing NODE=%s 🐋\t\n" "${V}"
  VER=$(echo "${JSON}" | jq "[.[] | select(.version|test(\"^v${V}\"))][0].version" -r)
  NODEPATH="${ACT_TOOLSDIRECTORY}/node/${VER:1}/${ARCH}"

  mkdir -v -m 0777 -p "$NODEPATH"
  wget -qO- "https://nodejs.org/download/release/latest-v${V}.x/node-$VER-linux-$ARCH.tar.xz" | tar -Jxf - --strip-components=1 -C "$NODEPATH"

  # Making this Node version the default
  # NOTE: Disabled because we want to keep the version installed in act.sh
  # as the default version. At the point of writing this, this would be 22.
  #
  # ENVVAR="${V//\./_}"
  # echo "${ENVVAR}=${NODEPATH}" >>/etc/environment

  printf "\n\t🐋 Installed NODE 🐋\t\n"
  "$NODEPATH/bin/node" -v
done

# npm timeout under qemu with defaults.
set -x
npm config set fetch-timeout 120000
npm config set fetch-retry-mintimeout 120000
npm config set fetch-retry-maxtimeout 120000
npm config set prefer-offline true
npm config set registry http://registry.npmjs.org/
npm config set maxsockets 4
npm config set fetch-retries 4
# Otherwise there are no log updates for 10m+ on qemu
npm config set loglevel verbose
npm config ls -l

printf "\n\t🐋 Installing JS tools 🐋\t\n"
npm install -g npm
npm install -g pnpm
npm install -g yarn
# npm install -g grunt
# npm install -g gulp
# npm install -g n
# npm install -g parcel-bundler
npm install -g typescript
# npm install -g newman
# npm install -g vercel
# npm install -g webpack
# npm install -g webpack-cli
# npm install -g lerna
# npm install -g --unsafe-perm netlify-cli  # ISSUE: Doesn't work with npm 20 and 22 due to outdated sharp dependency

echo '::group::Version NPM'
npm -v
echo '::endgroup::'

echo '::group::Version PNPM'
pnpm -v
echo '::endgroup::'

echo '::group::Version YARN'
yarn -v
echo '::endgroup::'

echo '::group::Cleaning Up Image'
npm cache clean --force
rm -rf "$NVM_DIR/.cache"
apt-get clean
rm -rf /var/cache/* /var/log/* /var/lib/apt/lists/* /tmp/* || echo 'Failed to delete directories'
echo '::endgroup::'
