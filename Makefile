# DefOS bootable image build
#
# Produces:
#   disk_img/dimos.iso  - BIOS-bootable ISO image
#   disk_img/dimos.img  - bootable FAT12 floppy image
#   disk_img/dimos.hdd  - bootable FAT12 disk image
#
# Required tools: dd, mkfs.fat (dosfstools), mcopy/mdir (mtools), xorriso.

OUT      := disk_img
BOOT_IMG := $(OUT)/boot.img
ISO      := $(OUT)/dimos.iso
IMG      := $(OUT)/dimos.img
HDD      := $(OUT)/dimos.hdd
PAYLOAD  := $(OUT)/iso

.PHONY: all iso img hdd verify checksums clean

all: iso img hdd

iso: $(ISO) $(IMG) $(HDD)
img: $(IMG) $(HDD)
hdd: $(HDD)

# Build a 1.44 MiB bootable FAT12 image used for both the floppy/disk
# artifact and as the El Torito virtual floppy for the ISO.
$(BOOT_IMG):
	@mkdir -p $(OUT)
	rm -f $@
	dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	mkfs.fat -F 12 -n DEFOS $@
	mcopy -i $@ README.md ::README.TXT
	mcopy -i $@ LICENSE ::LICENSE.TXT

$(ISO): $(BOOT_IMG)
	rm -rf $(PAYLOAD)
	mkdir -p $(PAYLOAD)/boot
	cp $(BOOT_IMG) $(PAYLOAD)/boot/boot.img
	cp README.md $(PAYLOAD)/README.TXT
	cp game.project $(PAYLOAD)/game.project
	cp -r defos $(PAYLOAD)/defos
	cp -r example $(PAYLOAD)/example
	xorriso -as mkisofs \
	  -volid DEFOS \
	  -o $@ \
	  -b boot/boot.img \
	  -c boot/boot.cat \
	  -no-emul-boot \
	  -boot-load-size 4 \
	  -boot-info-table \
	  $(PAYLOAD)

$(IMG): $(BOOT_IMG)
	cp $< $@

$(HDD): $(IMG)
	cp $< $@

verify: iso
	@test -s $(ISO) || { echo "ERROR: $(ISO) is missing or empty"; exit 1; }
	@test -s $(IMG) || { echo "ERROR: $(IMG) is missing or empty"; exit 1; }
	@test -s $(HDD) || { echo "ERROR: $(HDD) is missing or empty"; exit 1; }
	@file $(ISO) $(IMG) $(HDD)

checksums: verify
	cd $(OUT) && sha256sum dimos.iso dimos.img dimos.hdd > SHA256SUMS

clean:
	rm -rf $(OUT)
