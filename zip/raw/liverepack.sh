#!/sbin/sh
#
# Copyright (C) 2016 Psych Half, <psych.half@gmail.com>
# Copyright (C) 2016 corphish, <d97.avinaba@gmail.com>
#
# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

set -x

# log to temp dir
exec >> "/tmp/liverepack.log" 2<&1

# configs, but this no general
BLK_KERNEL='/dev/block/bootdevice/by-name/boot'

# Kernel Params
CMDLINE="console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci lpm_levels.sleep_disabled=1 earlyprintk"
BASE=0x80000000
PAGESIZE=2048
RD_OFFSET=0x02000000
TAG_OFFSET=0x01e00000

# globals
XTRCT_DIR='/tmp/xtracted'
WORK_DIR='/tmp/liverepack'

# log trap
copylog_on_pre_exit() {
SD_PATH="/data/media/0"
ui_print "Copying log to $SD_PATH/liverepack.log"
rm "$SD_PATH/liverepack.log"
cp "/tmp/liverepack.log" "$SD_PATH/liverepack.log"
}

trap copylog_on_pre_exit EXIT

# ui_print
OUTFD=$(\
    /tmp/busybox ps | \
    /tmp/busybox grep -v "grep" | \
    /tmp/busybox grep -o -E "/tmp/updater .*" | \
    /tmp/busybox cut -d " " -f 3\
);

if /tmp/busybox test -e /tmp/update_binary ; then
    OUTFD=$(\
        /tmp/busybox ps | \
        /tmp/busybox grep -v "grep" | \
        /tmp/busybox grep -o -E "update_binary(.*)" | \
        /tmp/busybox cut -d " " -f 3\
    );
fi

ui_print() {
    if [ "${OUTFD}" != "" ]; then
        echo "ui_print ${1} " 1>&"${OUTFD}";
        echo "ui_print " 1>&"${OUTFD}";
    else
        echo "${1}";
    fi
}

setup_workspace() {
/tmp/busybox rm -rf "$WORK_DIR"
/tmp/busybox mkdir "$WORK_DIR"
if [ ! -d "$XTRCT_DIR" ]; then
ui_print  "FATAL: Nothing to repack"
exit 8
fi
/tmp/busybox cp "$XTRCT_DIR/Image.gz-dtb" "$WORK_DIR/Image.gz-dtb"
/tmp/busybox  cp "$XTRCT_DIR/dt.img" "$WORK_DIR/dt.img"
}

dump_bootimg() {
	ui_print "INFO: Dumping boot.img"
	/tmp/busybox dd if=/dev/block/bootdevice/by-name/boot of=/tmp/boot.img
	
}

unpack_bootimg() {
	ui_print "INFO: Unpacking boot.img"
	/tmp/unpackbootimg -i /tmp/boot.img -o /tmp/
	ui_print "INFO: Unpacked boot.img"
}

get_and_unpack_bootimg() {
	dump_bootimg
	unpack_bootimg
}

repack_bootimg() {
/tmp/mkbootimg --kernel $WORK_DIR/Image.gz-dtb --ramdisk /tmp/boot.img-ramdisk.gz --cmdline $CMDLINE  --base $BASE --pagesize $PAGESIZE --ramdisk_offset $RD_OFFSET --tags_offset $TAG_OFFSET --dt $WORK_DIR/dt.img -o $WORK_DIR/bootnew.img
if [ ! -e "$WORK_DIR/bootnew.img" ]; then
ui_print "FATAL: couldnt pack boot.img" 
exit 5
fi;
}

call_preflash() { 
"$XTRCT_DIR/hooks/preflash.sh" "${api}"
}


call_postflash() {
"$XTRCT_DIR/hooks/postflash.sh" "${api}"
}

flash_kernel() {
/tmp/busybox true
# raw write for now
/tmp/busybox dd if="$WORK_DIR/bootnew.img" of="$BLK_KERNEL"
ui_print "raw_write: ret=$?"
}


cleanup() {
/tmp/busybox true
# 
# umount /system
# /tmp/busybox rm -rf "$WORK_DIR"
# /tmp/busybox rm -rf "$XTRCT_DIR"
}

 
setup_workspace
get_and_unpack_bootimg
repack_bootimg
#call_preflash
flash_kernel
#call_postflash
cleanup

# uncomment for testing
# exit 11

