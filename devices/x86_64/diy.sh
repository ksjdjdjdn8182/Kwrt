#!/bin/bash
set -e

# 覆盖全局默认网关 10.0.0.1 → 192.168.2.1
CONFIG_GEN="package/base-files/files/bin/config_generate"
if [ -f "$CONFIG_GEN" ]; then
    sed -i 's/10.0.0.1/192.168.2.1/g' "$CONFIG_GEN"
fi

# 自定义ROOT密码
SHADOW_FILE="package/base-files/files/etc/shadow"
if [ -f "$SHADOW_FILE" ]; then
    sed -i 's/root::0:0:root:/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:root:/root:/bin/ash/' "$SHADOW_FILE"
fi

# 清除默认WAN绑定eth0，所有网卡默认LAN
NET_FILE="package/base-files/files/etc/board.d/99-default-network"
if [ -f "$NET_FILE" ]; then
    sed -i '/eth0/d' "$NET_FILE"
fi

# x86_64 固件编译全局参数
echo "CONFIG_TARGET_x86_64=y" >> .config
echo "CONFIG_TARGET_x86_64_EFI=y" >> .config
echo "CONFIG_TARGET_x86_64_LEGACY=y" >> .config
echo "CONFIG_TARGET_ROOTFS_EXT4FS=y" >> .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=4096" >> .config
echo "CONFIG_DOCKER=y" >> .config
echo "CONFIG_USB_SUPPORT=y" >> .config
echo "CONFIG_NGINX=y" >> .config

# 强制启用 OpenClash
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config
