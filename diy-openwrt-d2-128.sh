#!/bin/bash
set -x
#
# current directory is openwrt
CONF_FILE=".config"
MOD=`egrep "^CONFIG_TARGET_ramips_[^_]+=y" $CONF_FILE`
MOD=`awk -v FS='[_=\n]' '{print $4}' <<< $MOD`
KMOD="https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/"
# CURL_R=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | egrep "[0-9a-f]{32}" |sort | tail -n1`
# CURL_N=`awk -v FS='</a>|href=\"|/\">|-' '{print $4}' <<< $CURL_R`
# please check the version from https://downloads.openwrt.org/snapshots/targets/ramips/ 
CURRENT_VER="6.6"
CURRENT_YEAR=`date +%Y`
CURL_R=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | grep $CURRENT_VER | grep $CURRENT_YEAR | egrep "[0-9a-f]{32}" | awk -v FS='Sun|Mon|Tue|Wed|Thu|Fri|Sat' '{print $2}' | sort -M | tail -n1` 
CURL_S=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | grep $CURRENT_VER | grep $CURRENT_YEAR | grep "$CURL_R"`
CURL_N=`awk -v FS='</a>|href=\"|/\">|-' '{print $4}' <<< $CURL_S`
echo $CURL_N > vermagic

sed -i "s/grep '=\[ym\]' \$(LINUX_DIR)\/.config.set | LC_ALL=C sort | \$(MKHASH) md5 > \$(LINUX_DIR)\/.vermagic/cp \$(TOPDIR)\/vermagic \$(LINUX_DIR)\/.vermagic/" include/kernel-defaults.mk 
sed -i 's/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell \$(SCRIPT_DIR)\/kconfig.pl \$(LINUX_DIR)\/.config | mkhash md5)/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell cat \$(LINUX_DIR)\/.vermagic)/' package/kernel/linux/Makefile
sed -i 's/loglevel:-5/loglevel:-9/' package/utils/busybox/files/cron
# modify openwrt/blob/master/include/target.mk, conflict with dnsmasq-full
sed -i 's=dnsmasq \\=#dnsmasq \\=' include/target.mk
sed -i 's=odhcp6c \\=#odhcp6c \\=' include/target.mk
sed -i 's=odhcpd-ipv6only \\=#odhcpd-ipv6only \\=' include/target.mk
sed -i 's=ppp \\=#ppp \\=' include/target.mk
sed -i 's=ppp-mod-pppoe=#ppp-mod-pppoe=' include/target.mk
sed -i 's=kmod-nft-offload \\=kmod-nft-offload=' include/target.mk

# openssl in ssr-check 
# sed -i 's/+shadowsocksr-libev-ssr-check//' feeds/helloworld/luci-app-ssr-plus/Makefile

# fix libpcre missing
sed -i 's=+libpcre =+libpcre2 =' package/feeds/telephony/freeswitch/Makefile
grep libpcre package/feeds/telephony/freeswitch/Makefile

# if [[ "$MOD"  == "mt7621" ]]; then
#  echo "ip route add 192.168.128.0/24 via 192.168.125.253" >> package/network/config/firewall/files/firewall.hotplug
# fi

if [ ! -d files/etc/ssrplus ]; then
  mkdir -p files/etc/ssrplus
fi
curl -s https://raw.githubusercontent.com/gcp91020/myRouters/main/common_files/china_ip.txt -o files/etc/ssrplus/china_ssr.txt
curl -s https://raw.githubusercontent.com/gcp91020/myRouters/main/common_files/dnsmasq.conf  -o files/etc/ssrplus/gfw_list.conf
sed -i 's/PKG_USE_MIPS16/PKG_BUILD_FLAGS:=no-mips16\nPKG_USE_MIPS16/' feeds/helloworld/v2ray-plugin/Makefile

[ -e ../2024-dnsmasq.patch ] && /bin/cp ../2024-dnsmasq.patch package/network/services/dnsmasq/patches/ && ls -l package/network/services/dnsmasq/patches/

# cat package/network/services/dnsmasq/src/rfc1035.c
# [ -e ../200-ubus_dns.patch ] && /bin/cp ../200-ubus_dns.patch package/network/services/dnsmasq/patches/

echo "diy done"
