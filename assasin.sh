#!/bin/bash
 #
 # Copyright © 2016, Monish Kapadia "assasin.monish" <monishk10@yahoo.com>
 #
 # Custom Build script for ease.
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
 # Please maintain this if you use this script or any part of it
 #

###########################################################################
# Bash Color
blink_red='\033[05;31m'
red=$(tput setaf 1) 		  # red
green=$(tput setaf 2)             # green
cyan=$(tput setaf 6) 		  # cyan
txtbld=$(tput bold)               # Bold
bldred=${txtbld}$(tput setaf 1)   # red
bldgrn=${txtbld}$(tput setaf 2)   # green
bldblu=${txtbld}$(tput setaf 4)   # blue
bldcya=${txtbld}$(tput setaf 6)   # cyan
restore=$(tput sgr0)              # Reset
clear

###########################################################################
# Resources
THREAD="-j4"
KERNEL="Image"
DTBIMAGE="dt.img"
DEFCONFIG="miui_kenzo_defconfig"
device="kenzo"
COMPILER="/home/monish/kernel/Tools/aarch-arm64-5.3"

###########################################################################
# Kernel Details
BASE_ASSASIN_VER="assasin"
VER="v3"
ASSASIN_VER="$BASE_ASSASIN_VER$VER"

###########################################################################
# Vars
export ARCH=arm64
export CROSS_COMPILE="$COMPILER/bin/aarch64-linux-android-"
export LD_LIBRARY_PATH=$COMPILER/lib/
export KBUILD_BUILD_USER="monish"
export KBUILD_BUILD_HOST="beast"


###########################################################################
# Directory naming
#echo -e "${bldblu}"
#while read -p "Which branch (cm/miui)? " mchoice
#echo -e "${bldred}"
#do
#case "$mchoice" in
#	cm|CM )
#		ASSASIN_F="cm"
#		echo
#		echo "Named cm"
#		break
#		;;
#	m|M )
#		ASSASIN_F="miui"
#		echo
#		echo "Named miui"
#		break
#		;;
#	* )
#		echo
#		echo "Invalid try again!"
#		echo
#		;;
#esac
#done
#
###########################################################################

# Paths
#STRIP=/toolchain-path/arm-eabi-strip
STRIP=$COMPILER/bin/aarch64-linux-android-strip
KERNEL_DIR=`pwd`
ZIP_DIR="/home/monish/kernel"
REPACK_DIR="$ZIP_DIR/zip/kernel_zip/tools"
REPACK_DIR_1="$ZIP_DIR/zip/kernel_zip"
DTBTOOL_DIR="$ZIP_DIR/zip"
IMAGE_DIR="$KERNEL_DIR/arch/arm64/boot"

###########################################################################
# Functions

function make_dtb {
		$DTBTOOL_DIR/dtbToolCM -2 -o $KERNEL_DIR/arch/arm64/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
		#$DTBTOOL_DIR/dtbToolCM -2 -o $REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm64/boot/
		mv $KERNEL_DIR/arch/arm64/boot/dt.img $REPACK_DIR/dt.img

}
function clean_all {
		make clean && make mrproper
		cd arch/arm/boot/dts/
		rm *.dtb
}

function make_kernel {
		cd $KERNEL_DIR
		echo
		make $DEFCONFIG
		make $THREAD
		cp -vr $IMAGE_DIR/$KERNEL $REPACK_DIR/assassinImage
}

function make_zip {
		cd $REPACK_DIR_1
		zip -r9 ~/kernel/builds/AssassinX_kenzo_MIUI-$(date +%d-%m_%H%M).zip *
}

function copy_modules {
		echo "Copying modules"
		find . -name '*.ko' -exec cp {} $REPACK_DIR/ \;
		echo "Stripping modules for size"
		$STRIP --strip-unneeded $REPACK_DIR/*.ko
}

###########################################################################
DATE_START=$(date +"%s")

###########################################################################
echo -e "${bldred}"; echo -e "${blink_red}"; echo "$AK_VER"; echo -e "${restore}";

echo -e "${bldgrn}"
echo "----------------------"
echo "Making AssassinX Kernel:"
echo "----------------------"
echo -e "${restore}"

echo -e "${bldgrn}"
while read -p "Do you want to clean stuff (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done
echo -e "${restore}"
echo
echo -e "${txtbld}"
while read -p "Do you want to build kernel (y/n)? " dchoice
echo -e "${restore}"
do
case "$dchoice" in
	y|Y)
		make_kernel
		if [ -e "arch/arm64/boot/Image" ]; then
		make_dtb		
		copy_modules
		make_zip
		else
		echo -e "${bldred}"
		echo "Kernel Compilation failed, Image not found"
		echo -e "${restore}"
		exit 1
		fi
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done
echo -e "${bldgrn}"
echo "AssassinX_kenzo_MIUI-$(date +%d-%m_%H%M).zip"
echo -e "${bldred}"
echo "################################################################################"
echo -e "${bldgrn}"
echo "------------------------AssassinX Kernel Compiled in:-----------------------------"
echo -e "${bldred}"
echo "################################################################################"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo -e "${bldblu}"
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo -e "${restore}"
echo

