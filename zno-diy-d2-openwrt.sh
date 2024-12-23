#!/bin/bash
set -x
#
# current directory is openwrt
CONF_FILE=".config"
CURRENT_VER="5.10"
CURRENT_YEAR=`date +%Y`
MOD=`egrep "^CONFIG_TARGET_ramips_[^_]+=y" $CONF_FILE`
MOD=`awk -v FS='[_=\n]' '{print $4}' <<< $MOD`
KMOD="https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/"

#CURL_R=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | grep $CURRENT_VER | grep CURRENT_YEAR | egrep "[0-9a-f]{32}" |sort -M | tail -n1`
#CURL_N=`awk -v FS='</a>|href=\"|/\">|-' '{print $4}' <<< $CURL_R`
CURL_R=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | grep $CURRENT_VER | grep $CURRENT_YEAR | egrep "[0-9a-f]{32}" | awk -v FS='Sun|Mon|Tue|Wed|Thu|Fri|Sat' '{print $2}' | sort -M | tail -n1` 
CURL_S=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | grep $CURRENT_VER | grep $CURRENT_YEAR | grep "$CURL_R"`
CURL_N=`awk -v FS='</a>|href=\"|/\">|-' '{print $4}' <<< $CURL_S`
echo $CURL_N > vermagic

sed -i "s/grep '=\[ym\]' \$(LINUX_DIR)\/.config.set | LC_ALL=C sort | \$(MKHASH) md5 > \$(LINUX_DIR)\/.vermagic/cp \$(TOPDIR)\/vermagic \$(LINUX_DIR)\/.vermagic/" include/kernel-defaults.mk 
sed -i 's/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell \$(SCRIPT_DIR)\/kconfig.pl \$(LINUX_DIR)\/.config | mkhash md5)/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell cat \$(LINUX_DIR)\/.vermagic)/' package/kernel/linux/Makefile

# modify openwrt/blob/master/include/target.mk, conflict with dnsmasq-full
sed -i 's=dnsmasq \\=#dnsmasq \\=' include/target.mk

sed -i 's=kmod-nft-offload \\=kmod-nft-offload=' include/target.mk
sed -i '/dnsmasq \\/d' include/target.mk
sed -i '/odhcp6c \\/d' include/target.mk
sed -i '/odhcpd-ipv6only \\/d' include/target.mk
sed -i '/ppp \\/d' include/target.mk
sed -i '/ppp-mod-pppoe/d' include/target.mk


if [[ "$MOD"  == "mt7621" ]]; then
  echo "ip route add 192.168.128.0/24 via 192.168.125.253" >> package/network/config/firewall/files/firewall.hotplug
fi

if [[ -e files ]]; then
  curl -s https://raw.githubusercontent.com/gcp91020/myRouters/main/common_files/china_ip.txt -o files/etc/ssrplus/china_ssr.txt
  curl -s https://raw.githubusercontent.com/gcp91020/myRouters/main/common_files/dnsmasq.conf  -o files/etc/ssrplus/gfw_list.conf
fi
