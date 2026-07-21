#!/bin/bash
set -e

# ====================== 1. 基础定制配置（保留你的全部个性化） ======================
# 修改后台网段 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
# 自定义 root 密码
sed -i 's/root::0:0:root:/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:root:/root:/bin/ash/' package/base-files/files/etc/shadow
# 主机名 Kwrt
sed -i 's/OpenWrt/Kwrt/g' package/base-files/files/bin/config_generate
# 网卡全部默认 LAN，解除 WAN 绑定
sed -i '/eth0/d' package/base-files/files/etc/board.d/99-default-network
# 开启 ZRAM 内存压缩
echo "zram-swap" >> target/linux/x86/Makefile

# ====================== 2. 基础必备系统包（纯净无冲突） ======================
DEFAULT_PACKAGES=" autocore base-files bash block-mount ca-bundle coremark curl dnsmasq-full dropbear ds-lite e2fsprogs fdisk firewall4 fstools grub2-bios-setup htop kmod-8139cp kmod-8139too kmod-amazon-ena kmod-amd-xgbe kmod-atlantic kmod-bnx2 kmod-bnx2x kmod-button-hotplug kmod-drm-amdgpu kmod-drm-i915 kmod-dwmac-intel kmod-e1000 kmod-e1000e kmod-forcedeth kmod-fs-f2fs kmod-fs-vfat kmod-i40e kmod-iavf kmod-igb kmod-igbvf kmod-igc kmod-ixgbe kmod-ixgbevf kmod-lib-zstd kmod-mlx4-core kmod-mlx5-core kmod-mmc kmod-pcnet32 kmod-phy-broadcom kmod-r8101 kmod-r8125 kmod-r8126 kmod-r8168 kmod-sdhci kmod-tcp-bbr kmod-tg3 kmod-tulip kmod-usb-hid kmod-vmxnet3 libc libgcc libustream-mbedtls lm-sensors-detect logd lsblk luci-app-advancedplus luci-app-fan luci-app-filemanager luci-app-firewall luci-app-package-manager luci-app-syscontrol luci-app-upnp luci-app-wifihistory luci-app-wizard luci-base luci-compat luci-lib-fs luci-lib-ipkg mkf2fs mtd nano netifd odhcp6c odhcpd-ipv6only openssh-sftp-server opkg partx-utils pciutils ppp ppp-mod-pppoe resolveip swconfig uci uclient-fetch urandom-seed urngd usbutils wget-ssl zram-swap"

# ====================== 3. 纯净插件列表【仅 OpenClash 代理、零冲突】 ======================
# 已彻底删除所有会循环依赖的插件：passwall/ssr-plus/fchomo/neko/natmap/unblockneteasemusic/openclaw
CUSTOM_PACKAGES=" luci-app-accesscontrol-plus luci-app-acme luci-app-adbyby-plus luci-app-adguardhome luci-app-aria2 luci-app-aliyundrive-webdav luci-app-airplay2 luci-app-arpbind luci-app-cifs-mount luci-app-ddns luci-app-ddns-go luci-app-ddnsto luci-app-diskman luci-app-dufs luci-app-frpc luci-app-filebrowser luci-app-eqosplus luci-app-easytier luci-app-guest-wifi luci-app-hd-idle luci-app-frps luci-app-homeassistant luci-app-ipsec-server luci-app-ksmbd luci-app-kodexplorer luci-app-lucky luci-app-minidlna luci-app-mosdns luci-app-mwan3 luci-app-netdata luci-app-nlbwmon luci-app-oaf luci-app-openclash luci-app-parentcontrol luci-app-p910nd luci-app-openvpn-server-client luci-app-partexp luci-app-qbittorrent luci-app-qosmate luci-app-rclone luci-app-softethervpn luci-app-socat luci-app-snmpd luci-app-smartdns luci-app-samba4 luci-app-sqm-autorate luci-app-statistics luci-app-store luci-app-taskplan luci-app-tailscale-community luci-app-subconverter luci-app-timedreboot luci-app-timewol luci-app-transmission luci-app-ttyd luci-app-uugamebooster luci-app-turboacc luci-app-vlmcsd luci-app-vsftpd luci-app-watchcat luci-app-webdav luci-app-wrtbwmon luci-app-wireguard luci-app-wifischedule luci-app-wechatpush luci-app-xlnetacc luci-app-zerotier luci-theme-argon luci-theme-alpha luci-theme-material3 luci-theme-material luci-theme-aurora luci-theme-design luci-theme-kucat luci-theme-openwrt luci-theme-openwrt-2020 automount btop open-vm-tools qemu-ga kmod-iwlwifi iwlwifi-firmware kmod-mt7603 kmod-mt7612 kmod-mt7615 kmod-mt7622 kmod-rtl8821ce kmod-rtl8822be hostapd-wolf wpa-supplicant-wolf iw iw-full wireless-regdb"

# ====================== 4. 标准写入 .config（杜绝单行溢出报错） ======================
ALL_PACKAGES="$DEFAULT_PACKAGES $CUSTOM_PACKAGES"
rm -f .config
for pkg in $ALL_PACKAGES; do
    echo "CONFIG_PACKAGE_${pkg}=y" >> .config
done

# ====================== 5. 固件全局编译参数（x86_64 双启动+EXT4） ======================
echo "CONFIG_TARGET_x86_64=y" >> .config
echo "CONFIG_TARGET_x86_64_EFI=y" >> .config
echo "CONFIG_TARGET_x86_64_LEGACY=y" >> .config
echo "CONFIG_TARGET_ROOTFS_EXT4FS=y" >> .config
echo "CONFIG_TARGET_KERNEL_PARTSIZE=4096" >> .config
echo "CONFIG_DOCKER=y" >> .config
echo "CONFIG_USB_SUPPORT=y" >> .config
echo "CONFIG_NGINX=y" >> .config

# 强制锁定 OpenClash 编译
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config

# ====================== 6. 开机 8秒 自动重启网络（仅执行一次） ======================
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-once-network-reload <<'EOF'
#!/bin/sh
if [ ! -f /etc/network_reload_done ];then
    sleep 8
    uci commit network
    /etc/init.d/network restart
    touch /etc/network_reload_done
fi
EOF
chmod 755 package/base-files/files/etc/uci-defaults/99-once-network-reload
