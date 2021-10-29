
   
#!/bin/bash
set -x

CONF_FILE=".config"
MOD=`egrep "^CONFIG_TARGET_ramips_[^_]+=y" $CONF_FILE`
MOD=`awk -v FS='[_=\n]' '{print $4}' <<< $MOD`
if [[ "$MOD"  == "mt7621" ]]; then
  #sed -i "s/kmod-mt7603/kmod-mt7603e/" target/linux/ramips/image/mt7621.mk
  #grep mt7603 target/linux/ramips/image/mt7621.mk 
  git clone https://github.com/openwrt/openwrt openwrt-origin
  rm -rf toolchain/musl
  /bin/cp -rf openwrt-origin/toolchain/musl toolchain
  rm -rf openwrt-origin
  ls -l toolchain
fi
