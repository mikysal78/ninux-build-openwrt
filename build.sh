#!/bin/bash
set -e
set -x

TARGET=$1
OPENWRT_VERSION="v23.05.0-rc3"

ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BUILD_DIR="/mnt/nfs-firmware/${OPENWRT_VERSION}/${TARGET}"

cd ${ROOT_DIR}

if [[ "${TARGET}" != "lamobo_R1" ]] || [[ "${TARGET}" != "tplink_c2600" ]]
then
  # issue on lamobo_R1 or tplink_c2600
  # ERROR: package/network/services/ppp failed to build (build variant: default)
  export CONFIG_CCACHE=y
  export CCACHE_DIR=/tmp/ccache
  export CCACHE_MAXSIZE=10G
  export CCACHE_COMPILERCHECK="%compiler% -dumpmachine; %compiler% -dumpversion"
  rm -rf $CCACHE_DIR
  mkdir -m 777 $CCACHE_DIR

else
  export CLEAN_BUILD=true
fi
# Install all necessary packages
#sudo apt-get install build-essential subversion libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core libssl-dev unzip python wget time

if [[ ! -d openwrt/.git ]]
then
    rm -rf openwrt
    git clone https://github.com/openwrt/openwrt.git openwrt
fi

cd ${ROOT_DIR}/openwrt
git fetch -a

git reset --hard HEAD^
git checkout -f ${OPENWRT_VERSION}

# Patch kernel config to enable nf_conntrack_events
#patch ${ROOT_DIR}/openwrt/target/linux/generic/config-5.4 < ${ROOT_DIR}/configs/kernel-config.patch

rm -rf ${ROOT_DIR}/openwrt/files
cp -r ${ROOT_DIR}/root_files ${ROOT_DIR}/openwrt/files

# configure feeds
echo "src-git chilli https://github.com/openwisp/coova-chilli-openwrt.git" > feeds.conf
echo "src-git openwisp_config https://github.com/openwisp/openwisp-config.git^1.0.1" >> feeds.conf
echo "src-git openwisp_monitoring https://github.com/openwisp/openwrt-openwisp-monitoring.git" >> feeds.conf
sed '/telephony/d' feeds.conf.default >> feeds.conf

./scripts/feeds update -a -f
./scripts/feeds install -a -f
rm -rf package/feeds/luci/luci-app-apinger
rm -rf ${ROOT_DIR}/openwrt/.config*
cp ${ROOT_DIR}/configs/${TARGET}.config ${ROOT_DIR}/openwrt/.config
cat ${ROOT_DIR}/configs/base-config >> ${ROOT_DIR}/openwrt/.config
make defconfig


make defconfig

if [[ "${CLEAN_BUILD}" == "true" || "${CONFIG_CCACHE}" == "y" ]]
then
    make clean
fi

#  If you try compiling OpenWrt on multiple cores and don't download all source files for all dependency packages
#  it is very likely that your build will fail.
# https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#download_sources_and_multi_core_compile
make download

make -j$(nproc) || make V=s # Retry with full log if failed

mkdir -p $BUILD_DIR
echo "Copying ./bin contents to $BUILD_DIR"
cp -r bin/targets/* $BUILD_DIR
echo "Cleaning bin dir"
rm -rf ./bin/*
