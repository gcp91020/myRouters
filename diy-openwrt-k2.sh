#!/bin/bash
set -x
#
# current directory is openwrt
CONF_FILE=".config"
MOD=`egrep "^CONFIG_TARGET_ramips_[^_]+=y" $CONF_FILE`
MOD=`awk -v FS='[_=\n]' '{print $4}' <<< $MOD`
KMOD="https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/"
CURL_R=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | egrep "[0-9a-f]{32}" |sort | tail -n1`
CURL_N=`awk -v FS='</a>|href=\"|/\">|-' '{print $4}' <<< $CURL_R`
echo $CURL_N > vermagic

sed -i "s/grep '=\[ym\]' \$(LINUX_DIR)\/.config.set | LC_ALL=C sort | \$(MKHASH) md5 > \$(LINUX_DIR)\/.vermagic/cp \$(TOPDIR)\/vermagic \$(LINUX_DIR)\/.vermagic/" include/kernel-defaults.mk 
sed -i 's/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell \$(SCRIPT_DIR)\/kconfig.pl \$(LINUX_DIR)\/.config | mkhash md5)/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell cat \$(LINUX_DIR)\/.vermagic)/' package/kernel/linux/Makefile

# modify openwrt/blob/master/include/target.mk, conflict with dnsmasq-full
sed -i 's=dnsmasq \\=#dnsmasq \\=' include/target.mk
sed -i 's=ip6tables \\=#ip6tables \\=' include/target.mk
sed -i 's=odhcp6c \\=#odhcp6c \\=' include/target.mk
sed -i 's=odhcpd-ipv6only \\=#odhcpd-ipv6only \\=' include/target.mk
sed -i 's=ppp \\=#ppp \\=' include/target.mk
sed -i 's=ppp-mod-pppoe=#ppp-mod-pppoe=' include/target.mk

if [[ "$MOD"  == "mt7621" ]]; then
  #sed -i "s/kmod-mt7603/kmod-mt7603e/" target/linux/ramips/image/mt7621.mk
  grep mt7603 target/linux/ramips/image/mt7621.mk 
  echo "ip route add 192.168.128.0/24 via 192.168.125.253" >> package/network/config/firewall/files/firewall.hotplug
fi
if [[ "$MOD"  == "mt7620" ]]; then
  echo "ip route add 192.168.120.0/24 via 192.168.125.254" >> package/network/config/firewall/files/firewall.hotplug
fi

sed -i 's=+shadowsocksr-libev-ssr-check ==' feeds/helloworld/luci-app-ssr-plus/Makefile
sed -i 's%CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Client=y%#CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Client=y%' .config
