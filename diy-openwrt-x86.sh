#!/bin/bash
set -x
#
# current directory is openwrt
CONF_FILE=".config"
#MOD=`egrep "^CONFIG_TARGET_ramips_[^_]+=y" $CONF_FILE`
#MOD=`awk -v FS='[_=\n]' '{print $4}' <<< $MOD`
#KMOD="https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/"
#https://downloads.openwrt.org/snapshots/targets/x86/64/kmods/
#CURL_R=`curl -s "https://downloads.openwrt.org/snapshots/targets/ramips/$MOD/kmods/" | egrep "[0-9a-f]{32}" |sort | tail -n1`
# default 5.10 
# CONFIG_LINUX_5_10=y
VER=`egrep "^CONFIG_LINUX_.+=y" $CONF_FILE`
if [[ "$VER" == "" ]]; then
  ver=5.4
else
  ver=`echo $VER | sed -e "s/.*CONFIG_LINUX_//" | sed "s/=y//" | sed "s/_/./"`
fi
CURL_R=`curl -s "https://downloads.openwrt.org/snapshots/targets/x86/64/kmods/" | egrep $ver | egrep "[0-9a-f]{32}" `
DATE_1=`echo $CURL_R | sed  "s/<\/tr>/<\/tr>\n/g" | grep $ver | egrep "[0-9a-f]{32}" | awk -v FS='Mon |Tue |Wed |Thu |Fri |Sat |Sun |</td></tr>' '{print $2}' | sed -E "s/ ([0-9]) / 0\1 /" | awk -F ' ' '{print $4",-"$1"-,"$2","$3}' | sed -e "s/Jan/01/" | sed -e "s/Feb/02/" | sed -e "s/Mar/03/" | sed -e "s/Apr/04/" | sed -e "s/May/05/" | sed -e "s/Jun/06/" | sed -e "s/Jul/07/" | sed -e "s/Aug/08/" | sed -e "s/Sep/09/" | sed -e "s/Oct/10/" | sed -e "s/Nov/11/" | sed -e "s/Dec/12/"  | sort | tail -n1 | sed -e "s/-01-/Jan/" | sed -e "s/-02-/Feb/" | sed -e "s/-03-/Mar/" | sed -e "s/-04-/Apr/" | sed -e "s/-05-/May/" | sed -e "s/-06-/Jun/" | sed -e "s/-07-/Jul/" | sed -e "s/-08-/Aug/" | sed -e "s/-09-/Sep/" | sed -e "s/-10-/Oct/" | sed -e "s/-11-/Nov/" | sed -e "s/-12-/Dec/" | awk -F ',' '{print $2" "$3" "$4" "$1}' | sed -E "s/ 0([0-9]) / \1 /" `
echo $DATE_1
CURL_R1=`echo $CURL_R | sed  "s/<\/tr>/\n/g" | grep "$DATE_1" `
CURL_N=`awk -v FS='</a>|href=\"|/\">|-' '{print $4}' <<< $CURL_R1`
echo $CURL_N
#CURL_N="5550601e097a5b96a1f4c9b1d0c3808d"
echo $CURL_N > vermagic

sed -i "s/grep '=\[ym\]' \$(LINUX_DIR)\/.config.set | LC_ALL=C sort | \$(MKHASH) md5 > \$(LINUX_DIR)\/.vermagic/cp \$(TOPDIR)\/vermagic \$(LINUX_DIR)\/.vermagic/" include/kernel-defaults.mk 
sed -i 's/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell \$(SCRIPT_DIR)\/kconfig.pl \$(LINUX_DIR)\/.config | mkhash md5)/STAMP_BUILT:=\$(STAMP_BUILT)_\$(shell cat \$(LINUX_DIR)\/.vermagic)/' package/kernel/linux/Makefile

# modify openwrt/blob/master/include/target.mk, conflict with dnsmasq-full
sed -i 's=dnsmasq \\=#dnsmasq \\=' include/target.mk

if [[ "$MOD"  == "mt7621" ]]; then
  echo "ip route add 192.168.128.0/24 via 192.168.125.253" >> package/network/config/firewall/files/firewall.hotplug
fi

