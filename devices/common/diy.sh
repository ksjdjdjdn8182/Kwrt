#!/bin/bash
#=================================================
# 补充脚本依赖函数，避免单独执行报错
function git_clone_path() {
  trap 'rm -rf "$tmpdir"' EXIT
  branch="$1" rurl="$2"
  rootdir="$PWD"
  tmpdir="$(mktemp -d)" || exit 1
  git clone -b "$branch" --depth 1 --filter=blob:none --sparse "$rurl" "$tmpdir"
  cd "$tmpdir"
  git checkout $branch
  if [ "$?" != 0 ]; then
    echo "error on $rurl"
    exit 1
  fi
  git sparse-checkout init --cone
  git sparse-checkout set $@
  cp -rn ./* "$rootdir/"
  cd "$rootdir"
}
export -f git_clone_path

shopt -s extglob

# feeds源添加，极简无冲突
sed -i '$a src-git kiddin9 https://github.com/kiddin9/op-packages.git;main' feeds.conf.default
sed -i "/telephony/d" feeds.conf.default

sed -i "s?targets/%S/packages?targets/%S/\$(LINUX_VERSION)?" include/feeds.mk
sed -i '/	refresh_config();/d' scripts/feeds
sed -i "s?git.openwrt.org/\(project\|feed\)?github.com/openwrt?g" feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a -p kiddin9 -f
./scripts/feeds install -a

sed --follow-symlinks -i "s#%C\"#%C by Kiddin'\"#" package/base-files/files/etc/os-release
sed -i -e '$a /etc/bench.log' \
        -e '/\/etc\/profile/d' \
        -e '/\/etc\/shinit/d' \
        package/base-files/files/lib/upgrade/keep.d/base-files-essential
sed -i -e '/^\/etc\/profile/d' \
        -e '/^\/etc\/shinit/d' \
        package/base-files/Makefile
sed -i "s/192.168.1/10.0.0/" package/base-files/files/bin/config_generate

sed -i "s#false; \\\#true; \\\#" include/download.mk

# 下载各类内核补丁
wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/package/kernel/linux/modules/video.mk -P package/kernel/linux/modules/
wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/package/network/utils/nftables/patches/002-nftables-add-fullcone-expression-support.patch -P package/network/utils/nftables/patches/
wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/package/libs/libnftnl/patches/001-libnftnl-add-fullcone-expression-support.patch -P package/libs/libnftnl/patches/
wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/package/firmware/wireless-regdb/patches/600-custom-change-txpower-and-dfs.patch -P package/firmware/wireless-regdb/patches/
wget -N  https://github.com/coolsnowwolf/lede/raw/refs/heads/master/package/system/fstools/patches/0200-ntfs3-with-utf8.patch -P package/system/fstools/patches/
wget -N https://github.com/immortalwrt/immortalwrt/raw/refs/heads/openwrt-25.12/config/Config-kernel.in -P config/

# 替换openssl与ppp源码
rm -rf package/libs/openssl package/network/services/ppp
git_clone_path openwrt-25.12 https://github.com/immortalwrt/immortalwrt package/libs/openssl package/network/services/ppp

echo "$(date +"%s")" >version.date
sed -i '/$(curdir)\/compile:/c\$(curdir)/compile: package/opkg/host/compile' package/Makefile

# 固件默认软件包列表
sed -i "s/DEFAULT_PACKAGES:=/DEFAULT_PACKAGES:=luci-app-advancedplus luci-app-firewall luci-app-package-manager luci-app-upnp luci-app-syscontrol \
luci-app-wizard luci-base luci-compat luci-lib-ipkg luci-lib-fs \
coremark wget-ssl curl autocore htop nano zram-swap kmod-lib-zstd kmod-tcp-bbr bash openssh-sftp-server block-mount resolveip ds-lite swconfig luci-app-fan luci-app-filemanager luci-app-wifihistory /" include/target.mk

sed -i "s/^.*vermagic$/\techo '1' > \$(LINUX_DIR)\/.vermagic/" include/kernel-defaults.mk

# 固定分支，无任何GitHub API查询逻辑
REPO_BRANCH="openwrt-25.12"

# 注释kiddin9 API等待循环，消除额外github接口请求
# status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/kiddin9/op-packages/actions/runs" | jq -r '.workflow_runs[0].status')
# echo "$status"
# while [[ "$status" == "in_progress" || "$status" == "queued" ]];do
# 	echo "wait 5s"
# 	sleep 5
# 	status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/kiddin9/op-packages/actions/runs" | jq -r '.workflow_runs[0].status')
# done

wget -N https://raw.githubusercontent.com/openwrt/packages/master/lang/golang/golang/Makefile -P feeds/packages/lang/golang/golang/

sed -i "/+= targz/d" include/image.mk

# 拉取lede内核hack补丁
mkdir -p target/linux/generic/
TMP_HACK=$(mktemp -d)
git clone -b master --depth 1 https://github.com/coolsnowwolf/lede "$TMP_HACK"
cp -rf "$TMP_HACK/target/linux/generic/hack-6.12" target/linux/generic/
rm -rf "$TMP_HACK"

rm -rf target/linux/generic/hack-6.12/767-net-phy-realtek-add-led*
wget -N https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/pending-6.12/613-netfilter_optional_tcp_window_check.patch -P target/linux/generic/pending-6.12/

# uhttpd并发调整
sed -i 's/max_requests 3/max_requests 20/g' package/network/services/uhttpd/files/uhttpd.config
sed -i "s/tty\(0\|1\)::askfirst/tty\1::respawn/g" target/linux/*/base-files/etc/inittab

date=`date +"%m.%d.%Y"`
sed -i -e "/\(# \)\?REVISION:=/c\REVISION:=$date" -e '/VERSION_CODE:=/c\VERSION_CODE:=$(REVISION)' include/version.mk

# rpcd超时延长
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config

# ===================== 已完整加回移除的kiddin9包替换逻辑，拆分多条sed无正则分组 =====================
sed -i 's|+luci | |g' package/feeds/kiddin9/*/Makefile
sed -i 's|+luci-ssl | |g' package/feeds/kiddin9/*/Makefile
sed -i 's|+uhttpd | |g' package/feeds/kiddin9/*/Makefile
sed -i 's|+nginx |+nginx-ssl |g' package/feeds/kiddin9/*/Makefile
sed -i 's|+python |+python3 |g' package/feeds/kiddin9/*/Makefile

# 加回golang路径替换语句，无分组正则不会冲突
sed -i 's|../../lang|$(TOPDIR)/feeds/packages/lang|' package/feeds/kiddin9/*/Makefile
# ==================================================================================================================

# 固件名称修改为Kwrt
sed -i "s/OpenWrt/Kwrt/g" package/base-files/files/bin/config_generate package/base-files/image-config.in package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc config/Config-images.in Config.in include/u-boot.mk include/version.mk || true

# WIFI区域码设置中国
sed -i -e "s/set \${s}.country='\${country || ''}'/set \${s}.country='\${country || \"CN\"}'/g" -e "s/set \${s}.disabled=.*/set \${s}.disabled='0'/" package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc

# 删除jool ipv6模块
rm -rf package/feeds/packages/jool
