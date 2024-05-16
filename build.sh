#!/bin/bash
clear
function compile() 
{
echo InfixKernel-spaced, CODENAMED - spaced
echo
sleep 3 >/dev/null
source ~/.bashrc && source ~/.profile
export LC_ALL=C && export USE_CCACHE=1
ccache -M 100G >/dev/null
TANGGAL=$(date +"%Y%m%d-%H")
export ARCH=arm64
export KBUILD_BUILD_HOST=InfixKernel-spaced
export KBUILD_BUILD_USER="HELLINFIX"

sudo apt install -y libelf-dev libarchive-tools zstd flex bc ccache

clangbin=clang/bin/clang
if ! [ -a $clangbin ]; then git clone --depth=1 https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r487747c.git -b 14.0 clang
fi
gcc64bin=gcc64/bin/aarch64-linux-android-as
if ! [ -a $gcc64bin ]; then git clone --depth=1 --single-branch https://github.com/mvaisakh/gcc-arm64.git gcc64
fi
gcc32bin=gcc32/bin/arm-linux-androideabi-as
if ! [ -a $gcc32bin ]; then git clone --depth=1 --single-branch https://github.com/mvaisakh/gcc-arm.git gcc32
fi
read -p "Wanna do dirty build? (Y/N): " build_type
if [[ $build_type == "N" || $build_type == "n" ]]; then
echo Deleting out directory and doing clean Build
sleep 3 >/dev/null
rm -rf out && mkdir -p out
fi
if [[ $build_type == "Y" || $build_type == "y" ]]; then
echo Warning :- Doing dirty build
sleep 3 >/dev/null
fi
if ! [[ $build_type == "Y" || $build_type == "y" ]]; then
if ! [[ $build_type == "N" || $build_type == "n" ]]; then
echo Invalid Input , Read carefully before typing
echo Trying to restart script
sleep 3 >/dev/null
. build.sh && exit
fi
fi

make O=out ARCH=arm64 spaced_defconfig

PATH="${PWD}/clang/bin:${PATH}:${PWD}/gcc32/bin:${PATH}:${PWD}/gcc64/bin:${PATH}" \
make -j$(nproc --all)   O=out \
                        ARCH=arm64 \
                        CC="clang" \
                        CLANG_TRIPLE=aarch64-linux-gnu- \
                        CROSS_COMPILE="${PWD}/gcc64/bin/aarch64-linux-gnu-" \
                        CROSS_COMPILE_ARM32="${PWD}/gcc32/bin/arm-linux-gnueabi-" \
                        LD=ld.lld \
                        AS=llvm-as \
                        AR=llvm-ar \
                        NM=llvm-nm \
                        LLVM=1 \
                        LLVM_IAS=1 \
                        OBJCOPY=llvm-objcopy \
                        STRIP=llvm-strip \
                        CONFIG_NO_ERROR_ON_MISMATCH=y 2>&1 | tee error.log 
}

function zupload()
{
zimage=out/arch/arm64/boot/Image.gz-dtb
if ! [ -a $zimage ];
then
echo  " Failed to compile zImage, fix the errors first "
else
echo -e " Build succesful, generating flashable zip now "
rm -rf AnyKernel
git clone --depth=1 https://github.com/HELLINFIX/AnyKernel3 AnyKernel
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
cd AnyKernel
zip -r9 InfixKernel-spaced-${TANGGAL}.zip *
curl -sL https://git.io/file-transfer | sh
./transfer fio InfixKernel-spaced-${TANGGAL}.zip
cd ../
fi
}

compile
zupload
