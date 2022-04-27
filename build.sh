#!/usr/bin/env bash

 #
 # Script For Building Android Kernel
 #

if [ ! -d "${PWD}/kernel_ccache" ]; 
    then
    mkdir -p "${PWD}/kernel_ccache"
    fi
    export CCACHE_DIR="${PWD}/kernel_ccache"
    export CCACHE_EXEC=$(which ccache)
    export USE_CCACHE=1
    ccache -M 2G
    ccache -z

# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

# Kernel Defconfig
DEFCONFIG=vendor/citrus-perf_defconfig

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb

# Date and Time
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME=mobx
FINAL_ZIP=${ZIPNAME}-Kernel-${TANGGAL}.zip

# Clone ToolChain & AnyKernel
function cloneTC() {
        mkdir aosp-clang
        cd aosp-clang || exit
        
	    wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r437112b.tar.gz
        tar -xf clang*
        cd .. || exit
        
	    git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
	
	    git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32

        git clone --depth=1 https://github.com/reaPeR1010/AnyKernel3
        
        PATH="${KERNEL_DIR}/aosp-clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
        make -j$(nproc) O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
        make -j$(nproc) ARCH=arm64 O=out \
        CC=clang \
        CLANG_TRIPLE=aarch64-linux-gnu- \
	    CROSS_COMPILE=aarch64-linux-android- \
	    CROSS_COMPILE_COMPAT=arm-linux-androideabi- \
	    V=$VERBOSE 2>&1 | tee error.log

	# Verify Files
	if ! [ -a "$IMAGE" ];
	   then
	       push "error.log" "Build Throws Errors"
	       exit 1
	   else
	       post_msg " Kernel Compilation Finished. Started Zipping "
	fi

}


function zipping() {
	# Copy Files To AnyKernel3 Zip
	cp $IMAGE AnyKernel3
	
	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${FINAL_ZIP} *
        MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
        push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
        cd ..
}


function post_msg() {
	curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
	-d chat_id="$chat_id" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
}

function push() {
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
}


cloneTC
END=$(date +"%s")
DIFF=$(($END - $START))
zipping




