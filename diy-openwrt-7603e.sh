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

sudo apt-get remove autoconf
wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz &&  tar zxvf autoconf-2.71.tar.gz && cd autoconf-2.71 && ./configure && make && sudo make install && cd ..

#automake 又出问题了 WARNING: 'automake-1.16' is missing on your system.
#rm -rf tools/automake
sudo apt-get remove automake
wget https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.gz && tar zxvf automake-1.16.5tar.gz && cd automake-1.16.5 && ./configure && make && sudo make install && cd ..

cd package/utils/util-linux/
autoscan
aclocal
autoconf
automake --add-msssing
cd ../../../

#sed -i 's#grep \'=[ym]\' \$(LINUX_DIR)/.config.set | LC_ALL=C sort | mkhash md5 > $(LINUX_DIR)/.vermagic#cp \$(TOPDIR)/vermagic \$(LINUX_DIR)/.vermagic#g' include/kernel-defaults.mk 
#sed -i 's#STAMP_BUILT:=$(STAMP_BUILT)_$(shell $(SCRIPT_DIR)/kconfig.pl $(LINUX_DIR)/.config | mkhash md5)#STAMP_BUILT:=$(STAMP_BUILT)_$(shell cat $(LINUX_DIR)/.vermagic)#g' package/kernel/linux/Makefile

# modify openwrt/blob/master/include/target.mk, conflict with dnsmasq-full
sed -i 's=dnsmasq \\=#dnsmasq \\=' include/target.mk

#current directory is openwrt
git config --global http.sslverify false && git clone https://github.com/coolsnowwolf/lede lede
/bin/cp -rf lede/package/lean/mt package/
/bin/cp -rf lede/package/lean/mtk-eip93 package/
rm -rf target/linux/ramips/mt7621
/bin/cp -rf lede/target/linux/ramips/mt7621 target/linux/ramips/
/bin/cp -rf lede/target/linux/ramips/image/mt7621.mk target/linux/ramips/image/mt7621.mk 
ls -l package/mt
ls -l target/linux/ramips/mt7621
ls -l target/linux/ramips/image/mt7621.mk 
rm -rf target/linux/ramips/files/drivers/net/ethernet/ralink
/bin/cp -rf lede/target/linux/ramips/files/drivers/net/ethernet/ralink target/linux/ramips/files/drivers/net/ethernet
ls -l target/linux/ramips/files/drivers/net/ethernet
/bin/cp -f lede/target/linux/ramips/mt7621/base-files/lib/preinit/07_mt7621_bringup_dsa_master target/linux/ramips/mt7621/base-files/lib/preinit/07_mt7621_bringup_dsa_master
/bin/cp -f lede/target/linux/ramips/patches-5.10/999-fix-hwnat.patch target/linux/ramips/patches-5.10/999-fix-hwnat.patch

#怎么 of_get_mac_address 不一致了呢?
sed -i '/\tmac_addr = of_get_mac_address/i \\tof_get_mac_address(priv->dev->of_node, dev->dev_addr);' target/linux/ramips/files/drivers/net/ethernet/ralink/mtk_eth_soc.c
sed -i '/\tmac_addr = of_get_mac_address/i \/\*' target/linux/ramips/files/drivers/net/ethernet/ralink/mtk_eth_soc.c
sed -i '/.*ether_addr_copy(dev->dev_addr, mac_addr);/a \*\/' target/linux/ramips/files/drivers/net/ethernet/ralink/mtk_eth_soc.c
grep mac_addr target/linux/ramips/files/drivers/net/ethernet/ralink/mtk_eth_soc.c

#rm -rf tar devel/autoconf
#/bin/cp -rf lede/tools/autoconf dev/
#ls -l dev/

rm -rf lede
#改动autoconf 有没有必要啊? 不管了，反正更新下没有增加新的错误。
sed -i "s/PKG_VERSION:=2.69/PKG_VERSION:=2.71/" tools/autoconf/Makefile
sed -i "s/64ebcec9f8ac5b2487125a86a7760d2591ac9e1d3dbd59489633f9de62a57684/f14c83cfebcc9427f2c3cea7258bd90df972d92eb26752da4ddad81c87a0faa4/" tools/autoconf/Makefile
rm -rf tools/autoconf/patches
cat tools/autoconf/Makefile

sed -i "s/HOST_FIXUP/#HOST_FIXUP/" tools/dosfstools/Makefile
cat tools/dosfstools/Makefile

#rm -rf tools/libressl        
#wget https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.4.1.tar.gz 
#cd tools && tar zxvf ../libressl-3.4.1.tar.gz 
#mv libressl-3.4.1 libressl
#cd libressl

sed -i '/HOST_BUILD_PARALLEL:=1/a PKG_BUILD_DEPENDS:=gettext libiconv' tools/libressl/Makefile
sed -i "s/PKG_VERSION:=3.3.4/PKG_VERSION:=3.4.1/" tools/libressl/Makefile
sed -i "s/bcce767a3fed252bfd1210f8a7e3505a2b54d3008f66e43d9b95e3f30c072931/107ceae6ca800e81cb563584c16afa36d6c7138fade94a2b3e9da65456f7c61c/" tools/libressl/Makefile
cat tools/libressl/Makefile

#./configure && make && sudo make install 
#cd ../..
#sed -i "s/--disable-tests/--disable-tests --enable-m4_pattern_allow/" tools/libressl/Makefile
#sed -i 's/disable-tests/disable-tests /' tools/libressl/configure.ac
#cat tools/libressl/Makefile


#package/utils/util-linux 过不去了, 在yml 中改吧


if [[ "$MOD"  == "mt7621" ]]; then
  #sed -i "s/kmod-mt7603/kmod-mt7603e/" target/linux/ramips/image/mt7621.mk
  grep mt7603 target/linux/ramips/image/mt7621.mk 
  echo "ip route add 192.168.128.0/24 via 192.168.125.253" >> package/network/config/firewall/files/firewall.hotplug
fi
if [[ "$MOD"  == "mt7620" ]]; then
  echo "ip route add 192.168.120.0/24 via 192.168.125.254" >> package/network/config/firewall/files/firewall.hotplug
fi


