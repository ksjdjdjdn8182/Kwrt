#!/bin/bash
set -e

# ====================== 1. 基础网络/后台参数 ======================
# 后台地址 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
# 默认密码 root
sed -i 's/root::0:0:root:/root:/bin/ash/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:root:/root:/bin/ash/' package/base-files/files/etc/shadow
# 主机名 Kwrt
sed -i 's/OpenWrt/Kwrt/g' package/base-files/files/bin/config_generate
# 删除eth0默认WAN绑定，所有网卡默认LAN，杜绝插网线无IP
sed -i '/eth0/d' package/base-files/files/etc/board.d/99-default-network
# 开启zram内存交换
echo "zram-swap" >> target/linux/x86/Makefile

# ====================== 2. 出厂基础软件包（原始全套） ======================
DEFAULT_PACKAGES=" autocore base-files bash block-mount ca-bundle coremark curl dnsmasq-full dropbear ds-lite e2fsprogs fdisk firewall4 fstools grub2-bios-setup htop kmod-8139cp kmod-8139too kmod-amazon-ena kmod-amd-xgbe kmod-atlantic kmod-bnx2 kmod-bnx2x kmod-button-hotplug kmod-drm-amdgpu kmod-drm-i915 kmod-dwmac-intel kmod-e1000 kmod-e1000e kmod-forcedeth kmod-fs-f2fs kmod-fs-vfat kmod-i40e kmod-iavf kmod-igb kmod-igbvf kmod-igc kmod-ixgbe kmod-ixgbevf kmod-lib-zstd kmod-mlx4-core kmod-mlx5-core kmod-mmc kmod-pcnet32 kmod-phy-broadcom kmod-r8101 kmod-r8125 kmod-r8126 kmod-r8168 kmod-sdhci kmod-tcp-bbr kmod-tg3 kmod-tulip kmod-usb-hid kmod-vmxnet3 libc libgcc libustream-mbedtls lm-sensors-detect logd lsblk luci-app-advancedplus luci-app-fan luci-app-filemanager luci-app-firewall luci-app-package-manager luci-app-syscontrol luci-app-upnp luci-app-wifihistory luci-app-wizard luci-base luci-compat luci-lib-fs luci-lib-ipkg mkf2fs mtd nano netifd odhcp6c odhcpd-ipv6only openssh-sftp-server opkg partx-utils pciutils ppp ppp-mod-pppoe resolveip swconfig uci uclient-fetch urandom-seed urngd usbutils wget-ssl zram-swap"

# ====================== 3. 完整全套自定义插件（你提供的全部插件无删减） ======================
CUSTOM_PACKAGES=" luci-app-accesscontrol-plus luci-app-acme luci-app-adbyby-plus luci-app-adguardhome luci-app-aria2 luci-app-ap-modem luci-app-aliyundrive-webdav luci-app-airplay2 luci-app-arpbind luci-app-bandix luci-app-cifs-mount luci-app-broadbandacc luci-app-cupsd luci-app-cloudreve luci-app-cpulimit luci-app-clouddrive2 luci-app-ddns luci-app-ddns-go luci-app-ddnsto luci-app-diskman luci-app-dufs luci-app-frpc luci-app-filebrowser luci-app-eqosplus luci-app-easytier luci-app-easymesh luci-app-guest-wifi luci-app-hd-idle luci-app-frps luci-app-homeassistant luci-app-ipsec-server luci-app-linkease luci-app-ksmbd luci-app-kodexplorer luci-app-iptvhelper luci-app-lucky luci-app-minidlna luci-app-mosdns luci-app-msd_lite luci-app-mwan3 luci-app-netdata luci-app-npc luci-app-nft-timecontrol luci-app-natmap luci-app-fastnet luci-app-nlbwmon luci-app-oaf luci-app-openclaw luci-app-parentcontrol luci-app-p910nd luci-app-openvpn-server-client luci-app-openlist2 luci-app-partexp luci-app-qbittorrent luci-app-qosmate luci-app-quickfile luci-app-rclone luci-app-softethervpn luci-app-socat luci-app-snmpd luci-app-smartdns luci-app-samba4 luci-app-run luci-app-sqm-autorate luci-app-statistics luci-app-store luci-app-taskplan luci-app-tailscale-community luci-app-syncdial luci-app-subconverter luci-app-thunder luci-app-timedreboot luci-app-timewol luci-app-transmission luci-app-ttyd luci-app-uugamebooster luci-app-unishare luci-app-unblockneteasemusic luci-app-turboacc luci-app-vlmcsd luci-app-vsftpd luci-app-watchcat luci-app-webdav luci-app-wrtbwmon luci-app-wireguard luci-app-wifischedule luci-app-apfree-wifidog luci-app-wechatpush luci-app-xlnetacc luci-app-xunyou luci-app-zerotier luci-theme-argon luci-theme-alpha luci-theme-material3 luci-theme-material luci-theme-aurora luci-theme-design luci-theme-kucat luci-theme-openmptcprouter luci-theme-routerich luci-theme-spectra luci-theme-openwrt luci-theme-openwrt-2020 luci-theme-lightblue luci-theme-teleofis automount btop naiveproxy open-vm-tools qemu-ga tvhelper kmod-mt7921e kmod-mt7922-firmware kmod-mt76e"

# 合并软件包写入编译配置
echo "CONFIG_PACKAGES=\"$DEFAULT_PACKAGES $CUSTOM_PACKAGES\"" >> .config

# ====================== 4. 固件镜像/硬件参数 ======================
# EFI+Legacy双启动镜像
echo "CONFIG_TARGET_x86_64=y" >> .config
echo "CONFIG_TARGET_x86_64_EFI=y" >> .config
echo "CONFIG_TARGET_x86_64_LEGACY=y" >> .config
# 文件系统 Ext4
echo "CONFIG_TARGET_ROOTFS_EXT4FS=y" >> .config
# 内核分区大小
echo "CONFIG_TARGET_KERNEL_PARTSIZE=4096" >> .config
# 开启Docker
echo "CONFIG_DOCKER=y" >> .config
# USB无线网卡支持
echo "CONFIG_USB_SUPPORT=y" >> .config
# Web服务Nginx
echo "CONFIG_NGINX=y" >> .config
# 预装OpenClash
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config

# ====================== 5. 清空开机初始化脚本，避免篡改网络 ======================
echo "" > package/base-files/files/etc/uci-defaults/99-custom-init
