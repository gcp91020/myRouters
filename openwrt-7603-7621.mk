#
# MT7621 Profiles
#

include ./common-tp-link.mk

DEFAULT_SOC := mt7621

KERNEL_DTB += -d21
DEVICE_VARS += ELECOM_HWNAME LINKSYS_HWNAME

define Build/elecom-wrc-gs-factory
	$(eval product=$(word 1,$(1)))
	$(eval version=$(word 2,$(1)))
	$(eval hash_opt=$(word 3,$(1)))
	$(MKHASH) md5 $(hash_opt) $@ >> $@
	( \
		echo -n "ELECOM $(product) v$(version)" | \
			dd bs=32 count=1 conv=sync; \
		dd if=$@; \
	) > $@.new
	mv $@.new $@
endef

define Build/gemtek-trailer
	printf "%s%08X" ".GEMTEK." "$$(cksum $@ | cut -d ' ' -f1)" >> $@
endef

define Build/iodata-factory
	$(eval fw_size=$(word 1,$(1)))
	$(eval fw_type=$(word 2,$(1)))
	$(eval product=$(word 3,$(1)))
	$(eval factory_bin=$(word 4,$(1)))
	if [ -e $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) -a "$$(stat -c%s $@)" -lt "$(fw_size)" ]; then \
		$(CP) $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) $(factory_bin); \
		$(STAGING_DIR_HOST)/bin/mksenaofw \
			-r 0x30a -p $(product) -t $(fw_type) \
			-e $(factory_bin) -o $(factory_bin).new; \
		mv $(factory_bin).new $(factory_bin); \
		$(CP) $(factory_bin) $(BIN_DIR)/; \
	else \
		echo "WARNING: initramfs kernel image too big, cannot generate factory image" >&2; \
	fi
endef

define Build/iodata-mstc-header
	( \
		data_size_crc="$$(dd if=$@ ibs=64 skip=1 2>/dev/null | gzip -c | \
			tail -c 8 | od -An -tx8 --endian little | tr -d ' \n')"; \
		echo -ne "$$(echo $$data_size_crc | sed 's/../\\x&/g')" | \
			dd of=$@ bs=8 count=1 seek=7 conv=notrunc 2>/dev/null; \
	)
	dd if=/dev/zero of=$@ bs=4 count=1 seek=1 conv=notrunc 2>/dev/null
	( \
		header_crc="$$(dd if=$@ bs=64 count=1 2>/dev/null | gzip -c | \
			tail -c 8 | od -An -N4 -tx4 --endian little | tr -d ' \n')"; \
		echo -ne "$$(echo $$header_crc | sed 's/../\\x&/g')" | \
			dd of=$@ bs=4 count=1 seek=1 conv=notrunc 2>/dev/null; \
	)
endef

define Build/sercomm-tag-factory
	$(eval magic_const=$(word 1,$(1)))
	dd if=/dev/zero count=$$((0x200)) bs=1 of=$@.head 2>/dev/null
	dd if=/dev/zero count=$$((0x70)) bs=1 2>/dev/null | tr '\000' '0' | \
		dd of=$@.head conv=notrunc 2>/dev/null
	printf $(SERCOMM_HWVER) | dd of=$@.head bs=1 conv=notrunc 2>/dev/null
	printf $(SERCOMM_HWID) | dd of=$@.head bs=1 seek=$$((0x8)) conv=notrunc 2>/dev/null
	printf $(SERCOMM_SWVER) | dd of=$@.head bs=1 seek=$$((0x64)) conv=notrunc \
		2>/dev/null
	dd if=$(IMAGE_KERNEL) skip=$$((0x100)) iflag=skip_bytes 2>/dev/null of=$@.clrkrn
	dd if=$(IMAGE_KERNEL) count=$$((0x100)) iflag=count_bytes 2>/dev/null of=$@.hdrkrn0
	dd if=/dev/zero count=$$((0x100)) iflag=count_bytes 2>/dev/null of=$@.hdrkrn1
	wc -c < $@.clrkrn | tr -d '\n' | dd of=$@.head bs=1 seek=$$((0x70)) \
		conv=notrunc 2>/dev/null
	stat -c%s $@ | tr -d '\n' | dd of=$@.head bs=1 seek=$$((0x80)) \
		conv=notrunc 2>/dev/null
	printf $(magic_const) | dd of=$@.head bs=1 seek=$$((0x90)) conv=notrunc 2>/dev/null
	cat $@.clrkrn $@ | md5sum | awk '{print $$1;}' | tr -d '\n' | dd of=$@.head bs=1 \
	seek=$$((0x1e0)) conv=notrunc 2>/dev/null
	cat $@.head $@.hdrkrn0 $@.hdrkrn1 $@.clrkrn $@ > $@.new
	mv $@.new $@
	rm $@.head $@.clrkrn
endef


define Build/ubnt-erx-factory-image
	if [ -e $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) -a "$$(stat -c%s $@)" -lt "$(KERNEL_SIZE)" ]; then \
		echo '21001:7' > $(1).compat; \
		$(TAR) -cf $(1) --transform='s/^.*/compat/' $(1).compat; \
		\
		$(TAR) -rf $(1) --transform='s/^.*/vmlinux.tmp/' $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE); \
		$(MKHASH) md5 $(KDIR)/tmp/$(KERNEL_INITRAMFS_IMAGE) > $(1).md5; \
		$(TAR) -rf $(1) --transform='s/^.*/vmlinux.tmp.md5/' $(1).md5; \
		\
		echo "dummy" > $(1).rootfs; \
		$(TAR) -rf $(1) --transform='s/^.*/squashfs.tmp/' $(1).rootfs; \
		\
		$(MKHASH) md5 $(1).rootfs > $(1).md5; \
		$(TAR) -rf $(1) --transform='s/^.*/squashfs.tmp.md5/' $(1).md5; \
		\
		echo '$(BOARD) $(VERSION_CODE) $(VERSION_NUMBER)' > $(1).version; \
		$(TAR) -rf $(1) --transform='s/^.*/version.tmp/' $(1).version; \
		\
		$(CP) $(1) $(BIN_DIR)/; \
	else \
		echo "WARNING: initramfs kernel image too big, cannot generate factory image" >&2; \
	fi
endef

define Build/zytrx-header
	$(eval board=$(word 1,$(1)))
	$(eval version=$(word 2,$(1)))
	$(STAGING_DIR_HOST)/bin/zytrx -B '$(board)' -v '$(version)' -i $@ -o $@.new
	mv $@.new $@
endef

define Device/dsa-migration
  DEVICE_COMPAT_VERSION := 1.1
  DEVICE_COMPAT_MESSAGE := Config cannot be migrated from swconfig to DSA
endef

define Device/d-team_newifi-d2
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 32448k
  DEVICE_VENDOR := Newifi
  DEVICE_MODEL := D2
  DEVICE_COMPAT_VERSION := 1.1
  DEVICE_PACKAGES := kmod-mt7603e kmod-mt76x2e kmod-usb3 \
	kmod-usb-ledtrig-usbport luci-app-mtwifi -wpad-openssl
endef
TARGET_DEVICES += d-team_newifi-d2


