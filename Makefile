
.PHONY: all clean linux-clean uboot-clean bootloader-clean
.PHONY: linux linux-config uboot uboot-config bootloader rootfs misc md5sum hwpack

CONFILE=.config

ifeq ($(strip $(wildcard ${CONFILE})),)
   $(error "$(CONFILE)": No such file, Please run command "./configure" first)
endif

include $(CONFILE)

TOP_DIR=$(shell pwd)
CPUS=$$(($(shell cat /sys/devices/system/cpu/present | awk -F- '{ print $$2 }')+1))
#CPUS=1
Q=

KERNEL_SRC=$(TOP_DIR)/linux-actions
UBOOT_SRC=$(TOP_DIR)/u-boot-actions
ROOTFS_SRC=$(TOP_DIR)/rootfs
OWL_DIR=$(TOP_DIR)/owl-actions

SCRIPT_DIR=$(OWL_DIR)/scripts
BOARD_CONFIG_DIR=$(OWL_DIR)/$(IC_NAME)/boards/$(BOARD_NAME)
TOOLS_DIR=$(OWL_DIR)/tools

OUT_DIR=$(TOP_DIR)/output
BUILD_DIR=$(TOP_DIR)/build/$(IC_NAME)
BOOTLOAD_DIR=$(BUILD_DIR)/bootloader
MISC_DIR=$(BUILD_DIR)/misc
IMAGE_DIR=$(BUILD_DIR)/images
KERNEL_OUT_DIR=$(BUILD_DIR)/linux
K_BLD_CONFIG=$(KERNEL_OUT_DIR)/.config
UBOOT_OUT_DIR=$(BUILD_DIR)/u-boot
U_BLD_CONFIG=$(UBOOT_OUT_DIR)/.config
ROOTFS_DIR=$(BUILD_DIR)/rootfs

CROSS_COMPILE=arm-linux-gnueabihf-
export PATH:=$(TOOLS_DIR)/utils:$(PATH)

DATE_STR=$(shell date +%y%m%d)
FW_NAME=$(IC_NAME)_$(BOARD_NAME)_$(DATE_STR)

all: hwpack

$(K_BLD_CONFIG): linux-actions/.git
	$(Q)mkdir -p $(KERNEL_OUT_DIR)
	$(Q)$(MAKE) -C $(KERNEL_SRC) ARCH=$(ARCH) O=$(KERNEL_OUT_DIR) $(KERNEL_DEFCONFIG)

linux: $(K_BLD_CONFIG)
	$(Q)mkdir -p $(KERNEL_OUT_DIR)
	$(Q)$(MAKE) -C $(KERNEL_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(ARCH) O=$(KERNEL_OUT_DIR) dtbs
	$(Q)$(MAKE) -C $(KERNEL_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(ARCH) O=$(KERNEL_OUT_DIR) -j$(CPUS) uImage modules
	$(Q)$(MAKE) -C $(KERNEL_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(ARCH) O=$(KERNEL_OUT_DIR) INSTALL_MOD_PATH=$(KERNEL_OUT_DIR) -j$(CPUS) modules_install

linux-config: $(K_BLD_CONFIG)
	$(Q)$(MAKE) -C $(KERNEL_SRC) ARCH=$(ARCH) O=$(KERNEL_OUT_DIR) menuconfig

$(U_BLD_CONFIG): u-boot-actions/.git
	$(Q)mkdir -p $(UBOOT_OUT_DIR)
	$(Q)$(MAKE) -C $(UBOOT_SRC) O=$(UBOOT_OUT_DIR) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(ARCH) $(UBOOT_DEFCONFIG)

uboot: $(U_BLD_CONFIG)
	$(Q)$(MAKE) -C $(UBOOT_SRC) O=$(UBOOT_OUT_DIR) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(ARCH) -j$(CPUS) all u-boot-dtb.img
	$(Q)cd $(SCRIPT_DIR) && ./padbootloader $(UBOOT_OUT_DIR)/u-boot-dtb.img

uboot-config:
	$(Q)$(MAKE) -C $(UBOOT_SRC) O=$(UBOOT_OUT_DIR) ARCH=arm menuconfig

bootloader:
	$(Q)mkdir -p $(BOOTLOAD_DIR)
	$(Q)cd $(TOOLS_DIR)/utils && ./bootloader_pack $(OWL_DIR)/$(IC_NAME)/bootloader/bootloader.bin $(BOARD_CONFIG_DIR)/bootloader.ini $(BOOTLOAD_DIR)/bootloader.bin

misc:
	$(Q)echo "-- Build Fat Misc image --"
	$(Q)mkdir -p $(MISC_DIR)
	$(Q)mkdir -p $(IMAGE_DIR)
	$(Q)cp -r $(BOARD_CONFIG_DIR)/misc/* $(MISC_DIR)/
	$(Q)cp $(KERNEL_OUT_DIR)/arch/$(ARCH)/boot/uImage $(MISC_DIR)
	$(Q)cp $(KERNEL_OUT_DIR)/arch/$(ARCH)/boot/dts/$(KERNEL_DTS).dtb $(MISC_DIR)/kernel.dtb
	$(Q)cp $(BOARD_CONFIG_DIR)/uEnv.txt $(MISC_DIR)
	$(Q)dd if=/dev/zero of=$(IMAGE_DIR)/misc.img bs=1M count=$(MISC_IMAGE_SIZE)
	$(Q)$(TOOLS_DIR)/utils/makebootfat -o $(IMAGE_DIR)/misc.img -L misc -b $(SCRIPT_DIR)/bootsect.bin $(MISC_DIR)

rootfs:
	$(Q)mkdir -vp $(ROOTFS_DIR)/lib $(ROOTFS_DIR)/usr
	$(Q)cp -a $(ROOTFS_SRC)/debian-ubuntu/*  $(ROOTFS_DIR)
	$(Q)cp -rf $(KERNEL_OUT_DIR)/lib/modules  $(ROOTFS_DIR)/lib/

hwpack: uboot linux bootloader misc rootfs
	if [ -d ${OUT_DIR} ];then  \
		sudo rm -rf ${OUT_DIR}; \
	fi
	$(Q)mkdir -vp $(OUT_DIR)/bootloader $(OUT_DIR)/kernel $(OUT_DIR)/rootfs
	$(Q)cp $(UBOOT_OUT_DIR)/u-boot-dtb.img $(OUT_DIR)/bootloader
	$(Q)cp $(BOOTLOAD_DIR)/bootloader.bin  $(OUT_DIR)/bootloader
	$(Q)cp $(IMAGE_DIR)/misc.img    $(OUT_DIR)/kernel
	$(Q)cp -a $(ROOTFS_DIR)/*      $(OUT_DIR)/rootfs
	$(Q)sudo chown -R root:root $(OUT_DIR)/*
	cd $(OUT_DIR) && sudo tar -Jcf $(BOARD_NAME)_hwpack_$(DATE_STR).tar.xz bootloader kernel rootfs --remove-files
	cd $(OUT_DIR) && sudo md5sum *.* > $(BOARD_NAME)_hwpack_$(DATE_STR).md5
	
%/.git:
	$(Q)git submodule init
	$(Q)git submodule update $*

linux-clean:
	$(Q)$(MAKE) -C $(KERNEL_SRC) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(ARCH) O=$(KERNEL_OUT_DIR) clean

uboot-clean:
	$(Q)$(MAKE) -C $(UBOOT_SRC) CROSS_COMPILE=$(CROSS_COMPILE) O=$(UBOOT_OUT_DIR) clean

bootloader-clean:
	@echo ""
clean:
	rm -f   $(TOP_DIR)/.config
	rm -rf 	$(TOP_DIR)/output
	rm -rf  $(TOP_DIR)/build
help:
	@echo ""
	@echo "Usage:"
	@echo "Optional targets:"
	@echo "  make hwpack          - Builds platform firmware package"
	@echo "  make linux           - Builds linux kernel"
	@echo "  make linux-clean     - Clean linux kernel"
	@echo "  make linux-config    - Menuconfig"
	@echo "  make uboot           - Builds u-boot"
	@echo "  make uboot-config    - Menuconfig"
	@echo "  make uboot-clean     - Clean uboot"
	@echo ""
	@echo "  make clean           - Clean all object files"
	@echo ""
