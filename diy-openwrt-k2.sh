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

if [[ "$MOD"  == "mt7621" ]]; then
  #sed -i "s/kmod-mt7603/kmod-mt7603e/" target/linux/ramips/image/mt7621.mk
  grep mt7603 target/linux/ramips/image/mt7621.mk 
  echo "ip route add 192.168.128.0/24 via 192.168.125.253" >> package/network/config/firewall/files/firewall.hotplug
fi
if [[ "$MOD"  == "mt7620" ]]; then
  sed -i 's=ip6tables \\=#ip6tables \\=' include/target.mk
  sed -i 's=odhcp6c \\=#odhcp6c \\=' include/target.mk
  sed -i 's=odhcpd-ipv6only \\=#odhcpd-ipv6only \\=' include/target.mk
  sed -i 's=ppp \\=#ppp \\=' include/target.mk
  sed -i 's=ppp-mod-pppoe=#ppp-mod-pppoe=' include/target.mk
  sed -i '/prompt "Enable IPv6 support in packages"/{n;d}' ./config/Config-build.in
  sed -i '/prompt "Enable IPv6 support in packages"/a \\t\tdefault n' ./config/Config-build.in
  sed -i '/DEVICE_VARIANT:= v22.4 or older/{n;d}' target/linux/ramips/image/mt7621.mk
  sed -i '/DEVICE_VARIANT:= v22.4 or older/a \\tDEVICE_PACKAGES := kmod-mt76x2 -ip6tables -odhcp6c -kmod-ipv6 -kmod-ip6tables -odhcpd-ipv6only -ppp -ppp-mod-pppoe' ./config/Config-build.in  
  
  #安装ssr plus，但是不安装 ssr
  sed -i 's=+shadowsocksr-libev-ssr-check ==' feeds/helloworld/luci-app-ssr-plus/Makefile
  sed -i '/bool "Include ShadowsocksR Libev Client"/{n;d}' feeds/helloworld/luci-app-ssr-plus/Makefile
  sed -i '/bool "Include ShadowsocksR Libev Client"/a \\tdefault n' feeds/helloworld/luci-app-ssr-plus/Makefile
  #sed -i '/INCLUDE_ShadowsocksR_Libev_Client:shadowsocksr-libev-ssr-local/,+3d' feeds/helloworld/luci-app-ssr-plus/Makefile 
  sed -i 's/default y/default n/' feeds/helloworld/xray-plugin/Makefile
  sed -i 's/default y/default n/' feeds/helloworld/v2ray-plugin/Makefile

  #echo "ip route add 192.168.120.0/24 via 192.168.125.254" >> package/network/config/firewall/files/firewall.hotplug
fi




