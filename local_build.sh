#!/bin/bash
set -e
set -x

OPENWRT_VERSION="v24.10.5"

OPTSTRING=":o:t:c:v:"

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    o)
      echo "Organization: ${OPTARG}"
      ORG=${OPTARG}
      ;;
    t)
      echo "Target: ${OPTARG}"
      TARGET=${OPTARG}
      ;;
    c)
      echo "Captive Portal: ${OPTARG}"
      CP=${OPTARG}
      ;;
    v)
      echo "VPN: ${OPTARG}"
      VPN=${OPTARG}
      ;;
    :)
      echo "Option -${OPTARG} requires an argument."
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ "${CP}" == "YES" ]; then
   BUILD_DIR="/mnt/nfs-firmware/${OPENWRT_VERSION}/${ORG}/CaptivePortal/${TARGET}"
 else
   BUILD_DIR="/mnt/nfs-firmware/${OPENWRT_VERSION}/${ORG}/Standard/${TARGET}"
fi

cd ${ROOT_DIR}

if [[ "${TARGET}" != "lamobo_R1" ]] || [[ "${TARGET}" != "tplink_c2600" ]]
then
  # issue on lamobo_R1 or tplink_c2600
  # ERROR: package/network/services/ppp failed to build (build variant: default)
  export CONFIG_CCACHE=y
  export CCACHE_DIR=/tmp/ccache
  export CCACHE_MAXSIZE=10G
  export CCACHE_COMPILERCHECK="%compiler% -dumpmachine; %compiler% -dumpversion"
  [ -d $CCACHE_DIR ] || mkdir -m 777 $CCACHE_DIR
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
#patch ${ROOT_DIR}/openwrt/target/linux/generic/config-5.10 < ${ROOT_DIR}/configs/kernel-config.patch

rm -rf ${ROOT_DIR}/openwrt/files

if [ "${CP}" == "YES" ]; then
echo "" > ${ROOT_DIR}/root_files/${ORG}/etc/uci-defaults/99-br-cp
    echo "#!/bin/sh
	uci -q batch <<-EOF >/dev/null
	set network.CP=interface
	set network.CP.auto='1'
	set network.CP.device='br-cp'
	set network.CP.proto='autoip'
	set network.CP.stp='1'
	set network.device_CP=device
	set network.device_CP.bridge_empty='1'
	set network.device_CP.ports='cpwlan0'
	set network.device_CP.name='br-cp'
	set network.device_CP.type='bridge'
	set network.device_CP.igmp_snooping='0'
	set network.device_CP.mtu='1500'
	commit network
	EOF" >> ${ROOT_DIR}/root_files/${ORG}/etc/uci-defaults/99-br-cp
fi

if [[ "${VPN}" == "ZeroTier" ]] || [[ "${VPN}" == "DualVPN" ]] ; then
echo "" > ${ROOT_DIR}/root_files/${ORG}/etc/uci-defaults/99-zerotier
    echo "#!/bin/sh
        uci -q batch <<-EOF >/dev/null
	set network.ZeroTier=interface
	set network.ZeroTier.proto='none'
	set network.ZeroTier.device='owzt0d3e97'
	commit network
        EOF" >> ${ROOT_DIR}/root_files/${ORG}/etc/uci-defaults/99-zerotier
fi

if [ "${CP}" == "NO" ]; then
   echo "" > ${ROOT_DIR}/root_files/${ORG}/etc/uci-defaults/99-br-cp
fi
cp -r ${ROOT_DIR}/root_files/${ORG} ${ROOT_DIR}/openwrt/files

# configure feeds
echo "src-git chilli https://github.com/mikysal78/coova-chilli-openwrt.git" > feeds.conf
echo "src-git openwisp_config https://github.com/openwisp/openwisp-config.git" >> feeds.conf
echo "src-git openwisp_monitoring https://github.com/openwisp/openwrt-openwisp-monitoring.git" >> feeds.conf
echo "src-git zerotier https://github.com/mwarning/zerotier-openwrt.git" >> feeds.conf
#echo "src-git zerotier https://github.com/mikysal78/zerotier-openwrt.git" >> feeds.conf
sed '/telephony/d' feeds.conf.default >> feeds.conf

./scripts/feeds update -a -f
./scripts/feeds install -a -f
rm -rf package/feeds/luci/luci-app-apinger
rm -rf ${ROOT_DIR}/openwrt/.config*
cp ${ROOT_DIR}/configs/organizations/${ORG}/${TARGET}.config ${ROOT_DIR}/openwrt/.config

if [ "${CP}" == "YES" ]; then
   cat ${ROOT_DIR}/configs/chilli.ext >> ${ROOT_DIR}/openwrt/.config
fi
cat ${ROOT_DIR}/configs/base.config >> ${ROOT_DIR}/openwrt/.config

##### VPN ####
#if [[ "${TARGET}" == "X86_64" ]] || [[ "${TARGET}" == "zyxel_nwa50ax-pro" ]] ; then
#    cat ${ROOT_DIR}/configs/wireguard.ext >> ${ROOT_DIR}/openwrt/.config
#fi

if [ "${VPN}" == "ZeroTier" ]; then
   cat ${ROOT_DIR}/configs/zerotier.ext >> ${ROOT_DIR}/openwrt/.config
fi

if [ "${VPN}" == "WireGuiard" ]; then
   cat ${ROOT_DIR}/configs/wireguard.ext >> ${ROOT_DIR}/openwrt/.config
fi

if [ "${VPN}" == "DualVPN" ]; then
   cat ${ROOT_DIR}/configs/wireguard.ext >> ${ROOT_DIR}/openwrt/.config
   cat ${ROOT_DIR}/configs/zerotier.ext >> ${ROOT_DIR}/openwrt/.config
fi
############

make defconfig

if [[ "${CLEAN_BUILD}" == "true" || "${CONFIG_CCACHE}" == "y" ]]
then
    make clean
fi

echo "Cleaning bin dir"
rm -rf ./bin/*

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
