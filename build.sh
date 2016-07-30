#!/bin/bash
 #
 # Copyright © 2016, Avinaba Dalal "corphish" <d97.avinaba@gmail.com>

 #
 # This software is licensed under the terms of the GNU General Public
 # License version 2, as published by the Free Software Foundation, and
 # may be copied, distributed, and modified under those terms.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
#
# Defaults
ARCH=arm64
DEFCONFIG=kenzo_defconfig
DEVICE=kenzo
LOCAL_PATH=$(pwd)
KERNEL=Image.gz-dtb
KERNEL_DIR=$LOCAL_PATH/arch/$ARCH/boot
KERNEL_PATH=$KERNEL_DIR/$KERNEL
ZIP_DIR=$LOCAL_PATH/zip/raw

# Tuneables
CROSS_COMPILE_LOCATION=home/boo/android/system/cm-13.0/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
CROSS_COMPILE=$CROSS_COMPILE_LOCATION/bin/aarch64-linux-android
DTBTOOL=$KERNEL_DIR/scripts/dtbTool
BUILD_HOST=fireball
BUILD_USER=boo

# Kernel params
# From device/xiaomi/kenzo/BoardConfig.mk
KERNEL_PAGESIZE=2048

# Colors
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

warn() {
	echo -e $yellow"Warning:"$nocol $@
}

error() {
	echo -e $red"Error:"$nocol $@
}

info() {
	echo -e $blue"Info:"$nocol $@
}

install() {
	echo -e $cyan"Install:"$nocol $@
}

export_variables() {
	export ARCH=$ARCH
	export CROSS_COMPILE=$CROSS_COMPILE
	export KBUILD_BUILD_HOST=$BUILD_HOST
	export KBUILD_BUILD_USER=$BUILD_USER
}

check_environment() {
	if [ -f "$KERNEL_PATH" ];
	then
		warn "You are making a dirty build"
	else		info "Making a clean build"
	fi
	if [ -d $ZIP_DIR ];
	then
		info "Template zip directory found, proceeding..."
	else
		error "Template zip directory not found. Aborting!!"
		exit
	fi	
}

clean() {
	make clean
	info "Cleaning output zips"
	rm -rf $LOCAL_PATH/zip/archives/*
	cd $ZIP_DIR
	rm -rf *~*
	rm -rf zImage
	cd $KERNEL_DIR
	rm -rf *Image*
	cd $LOCAL_PATH
	
}

build_kernel() {
	make $DEFCONFIG
	make Image.gz-dtb
	make dtbs
}

build_dt_img() {
		$DTBTOOL -o $LOCAL_PATH/arch/$ARCH/boot/dt.img -s $KERNEL_PAGESIZE -p $LOCAL_PATH/scripts/dtc/ $LOCAL_PATH/arch/arm/boot/dts/
}

collect_files() {
	cp $KERNEL_PATH $ZIP_DIR/files/
	cp $LOCAL_PATH/arch/$ARCH/boot/dt.img $ZIP_DIR/files/
	find . \
  		-not \( -path ./Documentation -prune \) \
  		-not \( -path ./include -prune \) \
 		-not \( -path ./Kbuild -prune \) \
  		-name \*.ko \
		-exec cp '{}' "$ZIP_DIR/modules/" ';'
}

strip() {
	find "$ZIP_DIR/modules" -type f -exec \
		 "${CROSS_COMPILE-}objcopy" --strip-unneeded '{}' ';'
}

make_zip() {
	# TODO: Better do python and use the technique used by Android build system.
	cd $ZIP_DIR
	zip -r ../archives/zd-$(date +"%Y%m%d")-$DEVICE.zip *
}

wrapper() {
	if [ "$1" == "clean" ];
	then info "Cleaning" && clean
	fi
	check_environment
	export_variables
	info "Building kernel.."
	build_kernel
	build_dt_img
	if [ ! -f $KERNEL_PATH ];
	then error "Build failed! Please fix the errors!" && exit
	fi
	info "Gathering all necessary files"
	collect_files
	info "Stripping modules"
	strip
	info "Making flashable zip"
	make_zip
	install $LOCAL_PATH/zip/archives/zd-$(date +"%Y%m%d")-$DEVICE.zip
}

wrapper $@
