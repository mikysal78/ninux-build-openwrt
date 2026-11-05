#!/bin/bash
# Applica (o toglie) le patch NINUX ai feed di OpenWrt.
#
# Le patch stanno in patches/feeds/<feed>/*.patch, con i percorsi relativi alla
# radice del feed (es. patches/feeds/luci/ -> openwrt/feeds/luci/).
#
# Uso, dalla cartella openwrt/:
#   ../feed_patches.sh revert   prima di "./scripts/feeds update": toglie le
#                               patch, così l'update trova i feed puliti
#   ../feed_patches.sh apply    dopo l'update: applica le patch
#
# Entrambe le operazioni si possono ripetere: una patch già applicata (o già
# tolta) viene saltata; una che non si applica più ferma la build.
set -e

ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ACTION=$1

for patch in "${ROOT_DIR}"/patches/feeds/*/*.patch; do
	[ -e "$patch" ] || continue
	feed=$(basename "$(dirname "$patch")")
	dir="${ROOT_DIR}/openwrt/feeds/${feed}"
	name="${feed}/$(basename "$patch")"
	[ -d "$dir" ] || { echo "feed ${feed} assente, salto ${name}"; continue; }

	applied=no
	git -C "$dir" apply --reverse --check "$patch" 2>/dev/null && applied=yes

	case "$ACTION" in
	apply)
		if [ $applied = yes ]; then
			echo "già applicata: ${name}"
		else
			git -C "$dir" apply "$patch"
			echo "applicata: ${name}"
		fi
		;;
	revert)
		if [ $applied = yes ]; then
			git -C "$dir" apply --reverse "$patch"
			echo "tolta: ${name}"
		fi
		;;
	*)
		echo "uso: $0 apply|revert" >&2
		exit 1
		;;
	esac
done
