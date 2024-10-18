myRouters

current version https://downloads.openwrt.org/snapshots/targets/ramips/
```
docker run -v ~/openwrt:/home/user -it --name openwrt openwrt_builder /bin/bash
docker exec -it openwrt /bin/bash entrypoint.sh
```

```
#!/bin/bash
rebuild(){
	rm -rf openwrt/* && rm -rf openwrt/.*
	git config --global http.sslverify false && git clone --depth 1 https://github.com/openwrt/openwrt -b master openwrt
	cd openwrt
	echo "src-git packages https://git.openwrt.org/feed/packages.git" > feeds.conf.default
	echo "src-git luci https://git.openwrt.org/project/luci.git" >> feeds.conf.default
	echo "src-git routing https://git.openwrt.org/feed/routing.git" >> feeds.conf.default
	echo "src-git sslibv https://github.com/gcp91020/shadowsocks-libev-new.git" >> feeds.conf.default
	echo "src-git telephony https://git.openwrt.org/feed/telephony.git" >> feeds.conf.default
	echo "src-git helloworld https://github.com/fw876/helloworld.git" >> feeds.conf.default

sed -i 's=libpcre=libpcre2=' package/feeds/telephony/freeswitch/Makefile

sed -i 's=dnsmasq \\=#dnsmasq \\=' include/target.mk
sed -i 's=odhcp6c \\=#odhcp6c \\=' include/target.mk
sed -i 's=odhcpd-ipv6only \\=#odhcpd-ipv6only \\=' include/target.mk
sed -i 's=ppp \\=#ppp \\=' include/target.mk
sed -i 's=ppp-mod-pppoe=#ppp-mod-pppoe=' include/target.mk
sed -i 's=kmod-nft-offload \\=kmod-nft-offload=' include/target.mk

	./scripts/feeds update -a
	./scripts/feeds update -a
	./scripts/feeds install -a
	cd ..
}

if [ -f openwrt/BSDmakefile ]; then
	echo "Delete current openwrt? (Y/N)" && read DEL
	DEL="${DEL:-N}"
	if [ "$DEL" == "Y" ]; then
		rebuild
	fi
else
	rebuild
fi
cd openwrt
make menuconfig
/bin/bash
```
