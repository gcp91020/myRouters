
   
#!/bin/bash
set -x

CONF_FILE=".config"
MOD=`egrep "^CONFIG_TARGET_ramips_[^_]+=y" $CONF_FILE`
MOD=`awk -v FS='[_=\n]' '{print $4}' <<< $MOD`
if [[ "$MOD"  == "mt7621" ]]; then
  #sed -i "s/kmod-mt7603/kmod-mt7603e/" target/linux/ramips/image/mt7621.mk
  #grep mt7603 target/linux/ramips/image/mt7621.mk 
  rm -rf openwrt/toolchain/musl/ 
  /bin/cp -rf musl toolchain/musl/
fi
