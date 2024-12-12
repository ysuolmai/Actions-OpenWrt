#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate
##-----------------Add dev core for kenzo OpenClash------------------
curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/dev/clash-linux-arm64.tar.gz -o /tmp/clash.tar.gz
tar zxvf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
chmod +x /tmp/clash >/dev/null 2>&1
mkdir -p package/kenzo/luci-app-openclash/root/etc/openclash/core
mv /tmp/clash package/kenzo/luci-app-openclash/root/etc/openclash/core/clash >/dev/null 2>&1
rm -rf /tmp/clash.tar.gz >/dev/null 2>&1


#DIY

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=${4:-} 
	

	rm -rf $(find feeds/luci/ feeds/packages/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune)

	if [[ $PKG_REPO == http* ]]; then
	        git clone --depth=1 --single-branch --branch $PKG_BRANCH "$PKG_REPO" package/$PKG_NAME
	        local REPO_NAME=$(echo $PKG_REPO | awk -F '/' '{gsub(/\.git$/, "", $NF); print $NF}')
	else
	        git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" package/$PKG_NAME
	        local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)
	fi
 
	if [[ $PKG_SPECIAL == "pkg" ]]; then
		cp -rf $(find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune) ./
		rm -rf ./$REPO_NAME/
	elif [[ $PKG_SPECIAL == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

# 添加额外插件
#git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff

# 科学上网插件
#UPDATE_PACKAGE "helloworld" "https://github.com/fw876/helloworld.git" "master"
#UPDATE_PACKAGE "homeproxy" "https://github.com/bulianglin/homeproxy.git" "master"

# Themes
#git clone --depth=1 -b 18.06 https://github.com/kiddin9/luci-theme-edge package/luci-theme-edge
#git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

#DDNS-go
git clone https://github.com/sirpdboy/luci-app-ddns-go.git package/ddns-go

#luci-app-zerotier
git clone https://github.com/rufengsuixing/luci-app-zerotier.git package/luci-app-zerotier

# iStore
#git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
#git_sparse_clone main https://github.com/linkease/istore luci

#gecoosac
#git clone https://github.com/lwb1978/openwrt-gecoosac package/openwrt-gecoosac

#lucky
#git clone  https://github.com/gdy666/luci-app-lucky.git package/lucky

#alist
UPDATE_PACKAGE "alist" "https://github.com/sbwml/luci-app-alist.git" "main"

UPDATE_PACKAGE "luci-app-adguardhome" "https://github.com/ysuolmai/luci-app-adguardhome.git" "master"

keywords_to_delete=(
    "xiaomi_ax3600" "xiaomi_ax9000" "xiaomi_ax1800" "glinet" "jdcloud_ax6600"
    "mr7350" "uugamebooster" "luci-app-wol" "luci-i18n-wol-zh-cn" "CONFIG_TARGET_INITRAMFS" "ddns" "apk" "wpad" "hostapd" "adblock" "usb-printer" "wireguard" "openvpn-server"
)

for keyword in "${keywords_to_delete[@]}"; do
    sed -i "/$keyword/d" ./.config
done

# Configuration lines to append to .config
provided_config_lines=(
    "CONFIG_PACKAGE_luci-app-zerotier=y"
    "CONFIG_PACKAGE_luci-i18n-zerotier-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-adguardhome=y"
    "CONFIG_PACKAGE_luci-i18n-adguardhome-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-poweroff=y"
    "CONFIG_PACKAGE_luci-i18n-poweroff-zh-cn=y"
    "CONFIG_PACKAGE_cpufreq=y"
    "CONFIG_PACKAGE_luci-app-cpufreq=y"
    "CONFIG_PACKAGE_luci-i18n-cpufreq-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-ttyd=y"
    "CONFIG_PACKAGE_luci-i18n-ttyd-zh-cn=y"
    "CONFIG_PACKAGE_ttyd=y"
    #"CONFIG_PACKAGE_luci-app-homeproxy=y"
    #"CONFIG_PACKAGE_luci-i18n-homeproxy-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-ddns-go=y"
    "CONFIG_PACKAGE_luci-i18n-ddns-go-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-argon-config=y"
    "CONFIG_BUSYBOX_CONFIG_LSUSB=n"
)

if [[ $FIRMWARE_TAG == *"NOWIFI"* ]]; then
    provided_config_lines+=(
        "CONFIG_PACKAGE_hostapd-common=n"
        "CONFIG_PACKAGE_wpad-openssl=n"
    )
else
    provided_config_lines+=(
        "CONFIG_PACKAGE_kmod-usb-net=y"
        "CONFIG_PACKAGE_kmod-usb-net-rndis=y"
        "CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y"
        "CONFIG_PACKAGE_usbutils=y"
    )
fi

[[ $FIRMWARE_TAG == *"EMMC"* ]] && provided_config_lines+=(
    "CONFIG_PACKAGE_luci-app-diskman=y"
    "CONFIG_PACKAGE_luci-i18n-diskman-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-docker=y"
    "CONFIG_PACKAGE_luci-i18n-docker-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-dockerman=y"
    "CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-alist=y"
    "CONFIG_PACKAGE_luci-i18n-alist-zh-cn=y"
)

# Append configuration lines to .config
for line in "${provided_config_lines[@]}"; do
    echo "$line" >> .config
done


#./scripts/feeds update -a
#./scripts/feeds install -a

#修复文件
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \;
sed -i '/\/usr\/bin\/zsh/d' package/base-files/files/etc/profile
#find ./ -path "*/usbutils/Makefile" -exec sed -i '/$(INSTALL_BIN) $(PKG_INSTALL_DIR)\/usr\/bin\/lsusb $(1)\/usr\/bin\//i rm -f $(1)/usr/bin/lsusb' {} \;
#find ./ -path "*/usbutils/Makefile" -exec sed -i '/$(INSTALL_BIN) $(PKG_INSTALL_DIR)\/usr\/bin\/lsusb $(1)\/usr\/bin\//i \\	rm -f $(1)/usr/bin/lsusb' {} \;
#find ./ -path "*/usbutils/Makefile" -exec sed -i 's|$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/lsusb $(1)/usr/bin/|$(INSTALL_BIN) -o $(PKG_INSTALL_DIR)/usr/bin/lsusb $(1)/usr/bin/|g' {} \;


find ./ -name "cascade.css" -exec sed -i 's/#5e72e4/#6fa49a/g; s/#483d8b/#6fa49a/g' {} \;
find ./ -name "dark.css" -exec sed -i 's/#5e72e4/#6fa49a/g; s/#483d8b/#6fa49a/g' {} \;
