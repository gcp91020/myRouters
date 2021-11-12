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

#sudo apt-get remove autoconf
#wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz &&  tar zxvf autoconf-2.71.tar.gz && cd autoconf-2.71 && ./configure && make && sudo make install && cd ..
#sudo apt-get install gtk-doc-tools

#automake 又出问题了 WARNING: 'automake-1.16' is missing on your system.
#sudo apt-get remove automake
#wget https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.gz && tar zxvf automake-1.16.5.tar.gz && cd automake-1.16.5 && ./configure && make && sudo make install && cd ..

#cd package/utils/util-linux/
#autoscan
#cd ../../../

# configure.ac:34: error: Please use exactly Autoconf 2.69 instead of 2.71
#rm -rf package/devel/binutils

#改动autoconf 有没有必要啊? 不管了，反正更新下没有增加新的错误。
#sed -i "s/PKG_VERSION:=2.69/PKG_VERSION:=2.71/" tools/autoconf/Makefile
#sed -i "s/64ebcec9f8ac5b2487125a86a7760d2591ac9e1d3dbd59489633f9de62a57684/f14c83cfebcc9427f2c3cea7258bd90df972d92eb26752da4ddad81c87a0faa4/" tools/autoconf/Makefile
#rm -rf tools/autoconf/patches
#cat tools/autoconf/Makefile

# modify openwrt/blob/master/include/target.mk, conflict with dnsmasq-full
sed -i 's=dnsmasq \\=#dnsmasq \\=' include/target.mk
sed -i 's=ip6tables \\=#ip6tables \\=' include/target.mk
sed -i 's=odhcp6c \\=#odhcp6c \\=' include/target.mk
sed -i 's=odhcpd-ipv6only \\=#odhcpd-ipv6only \\=' include/target.mk
sed -i 's=ppp \\=#ppp \\=' include/target.mk
sed -i 's=ppp-mod-pppoe=#ppp-mod-pppoe=' include/target.mk


#sed -i '/DEVICE_MODEL := D2/,/endef/{//!d}' target/linux/ramips/image/mt7621.mk
#sed -i 's/DEVICE_MODEL := D2/DEVICE_MODEL := D2\n  DEVICE_PACKAGES := kmod-mt7603e kmod-mt76x2e kmod-usb3 kmod-usb-ledtrig-usbport luci-app-mtwifi -wpad-openssl/' target/linux/ramips/image/mt7621.mk

#怎么 of_get_mac_address 不一致了呢?
#sed -i '/\tmac_addr = of_get_mac_address/i \\tof_get_mac_address(priv->dev->of_node, dev->dev_addr);' target/linux/ramips/files/drivers/net/ethernet/ralink/mtk_eth_soc.c
#sed -i '/\tmac_addr = of_get_mac_address/i \/\*' target/linux/ramips/files/drivers/net/ethernet/ralink/mtk_eth_soc.c
#sed -i '/.*ether_addr_copy(dev->dev_addr, mac_addr);/a \*\/' target/linux/ramips/files/drivers/net/ethernet/ralink/mtk_eth_soc.c
#grep mac_addr target/linux/ramips/files/drivers/net/ethernet/ralink/mtk_eth_soc.c

#稀奇古怪的bug
#sed -i "s/HOST_FIXUP/#HOST_FIXUP/" tools/dosfstools/Makefile
#cat tools/dosfstools/Makefile

#sed -i '/HOST_BUILD_PARALLEL:=1/a PKG_BUILD_DEPENDS:=gettext libiconv' tools/libressl/Makefile
#sed -i "s/PKG_VERSION:=3.3.4/PKG_VERSION:=3.4.1/" tools/libressl/Makefile
#sed -i "s/bcce767a3fed252bfd1210f8a7e3505a2b54d3008f66e43d9b95e3f30c072931/107ceae6ca800e81cb563584c16afa36d6c7138fade94a2b3e9da65456f7c61c/" tools/libressl/Makefile
#cat tools/libressl/Makefile

if [[ "$MOD"  == "mt7621" ]]; then
  #sed -i "s/kmod-mt7603/kmod-mt7603e/" target/linux/ramips/image/mt7621.mk
  grep mt7603 target/linux/ramips/image/mt7621.mk 
  echo "ip route add 192.168.128.0/24 via 192.168.125.253" >> package/network/config/firewall/files/firewall.hotplug
fi
if [[ "$MOD"  == "mt7620" ]]; then
  echo "ip route add 192.168.120.0/24 via 192.168.125.254" >> package/network/config/firewall/files/firewall.hotplug
fi
