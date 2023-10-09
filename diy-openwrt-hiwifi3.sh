#!/bin/bash
set -x
#=================================================
# Description: DIY script
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#=================================================
# Modify default IP
# sed -i 's/192.168.1.1/192.168.5.201/g' package/base-files/files/bin/config_generate

# Modify the version number
# sed -i 's/OpenWrt/Leopard build $(date "+%Y.%m.%d") @ OpenWrt/g' package/default-settings/files/zzz-default-settings

# 添加新的主题包
# git clone https://github.com/Leo-Jo-My/luci-theme-opentomcat.git package/lean/luci-theme-opentomcat

# 去除默认主题
# sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap

# current directory is openwrt
CONF_FILE=".config"
#MODU=`egrep "^CONFIG_TARGET_ramips_[^_]+=y" $CONF_FILE`
MODU=`egrep "^CONFIG_TARGET_ramips_[^_]+_DEVICE_.+=y" $CONF_FILE`
#CONFIG_TARGET_ramips_mt7620_DEVICE_hiwifi_hc5861=y
MOD=`awk -v FS='[_=\n]' '{print $4}' <<< $MODU`
MOD1=`awk -v FS='[_=\n]' '{print $7}' <<< $MODU`

KMOD="https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/"
#CURL_R=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | egrep "[0-9a-f]{32}" |sort | tail -n1`
#CURL_N=`awk -v FS='</a>|href=\"|/\">|-' '{print $4}' <<< $CURL_R`
#echo $CURL_N > vermagic

CURRENT_VER="5.15"
CURRENT_YEAR=`date +%Y`
CURL_R=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | grep $CURRENT_VER | grep $CURRENT_YEAR | egrep "[0-9a-f]{32}" | awk -v FS='Sun|Mon|Tue|Wed|Thu|Fri|Sat' '{print $2}' | sort -M | tail -n1` 
CURL_S=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | grep $CURRENT_VER | grep $CURRENT_YEAR | grep "$CURL_R"`
CURL_N=`awk -v FS='</a>|href=\"|/\">|-' '{print $4}' <<< $CURL_S`
echo $CURL_N > vermagic


sed -i "s/grep '=\[ym\]' \$(LINUX_DIR)\/.config.set | LC_ALL=C sort | \$(MKHASH) md5 > \$(LINUX_DIR)\/.vermagic/cp \$(TOPDIR)\/vermagic \$(LINUX_DIR)\/.vermagic/" include/kernel-defaults.mk 
sed -i 's/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell \$(SCRIPT_DIR)\/kconfig.pl \$(LINUX_DIR)\/.config | mkhash md5)/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell cat \$(LINUX_DIR)\/.vermagic)/' package/kernel/linux/Makefile

#sed -i 's#grep \'=[ym]\' \$(LINUX_DIR)/.config.set | LC_ALL=C sort | mkhash md5 > $(LINUX_DIR)/.vermagic#cp \$(TOPDIR)/vermagic \$(LINUX_DIR)/.vermagic#g' include/kernel-defaults.mk 
#sed -i 's#STAMP_BUILT:=$(STAMP_BUILT)_$(shell $(SCRIPT_DIR)/kconfig.pl $(LINUX_DIR)/.config | mkhash md5)#STAMP_BUILT:=$(STAMP_BUILT)_$(shell cat $(LINUX_DIR)/.vermagic)#g' package/kernel/linux/Makefile

sed -i 's/loglevel:-5/loglevel:-9/' package/utils/busybox/files/cron
#fix cron log = error
# modify openwrt/blob/master/include/target.mk, conflict with dnsmasq-full
sed -i 's=dnsmasq \\=#dnsmasq \\=' include/target.mk

if [[ "$MOD"  == "mt7621" ]]; then
  #sed -i "s/kmod-mt7603/kmod-mt7603e/" target/linux/ramips/image/mt7621.mk
  grep mt7603 target/linux/ramips/image/mt7621.mk 
  echo "ip route add 192.168.128.0/24 via 192.168.125.253" >> package/network/config/firewall/files/firewall.hotplug
fi
if [[ "$MOD1"  == "hc5861" ]]; then
  echo "ip route add 192.168.120.0/24 via 192.168.128.249" >> package/network/config/firewall/files/firewall.hotplug
  echo "ip route add 192.168.125.0/24 via 192.168.128.249" >> package/network/config/firewall/files/firewall.hotplug
fi
# if [ ! -d files/etc/ssrplus ]; then
#   mkdir -p files/etc/ssrplus
# fi
# curl -s https://raw.githubusercontent.com/gcp91020/myRouters/main/common_files/china_ip.txt -o files/etc/ssrplus/china_ssr.txt
# curl -s https://raw.githubusercontent.com/gcp91020/myRouters/main/common_files/dnsmasq.conf  -o files/etc/ssrplus/gfw_list.conf
sed -i 's/PKG_USE_MIPS16/PKG_BUILD_FLAGS:=no-mips16\nPKG_USE_MIPS16/' feeds/helloworld/v2ray-plugin/Makefile 
