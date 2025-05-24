#!/bin/env bash

# Define compile function
function compile() {
  # Load environment variables
  source ~/.bashrc
  source ~/.profile

  # Set environment variables
  export LC_ALL=C
  export USE_CCACHE=1

  TANGGAL=$(date +"%Y%m%d-%H")
  export ARCH=arm64
  export KBUILD_BUILD_HOST=Nebula
  export KBUILD_BUILD_USER="HELLINFIX"

  # Allocate 100GB of memory to ccache
  ccache -M 100G

  # Install Kernel Dependencies
  sudo apt update
  sudo apt install -y libelf-dev libarchive-tools zstd flex bc ccache

  # Download clang if not present
clangbin=clang/bin/clang
if ! [ -a $clangbin ]; then --depth=1 https://github.com/kdrag0n/proton-clang clang
fi
gcc64bin=los-4.9-64/bin/aarch64-linux-android-as
if ! [ -a $gcc64bin ]; then git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64
fi
gcc32bin=los-4.9-32/bin/arm-linux-androideabi-as
if ! [ -a $gcc32bin ]; then git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32
fi

# create output directory and do a clean or dirty build
  read -p "Wanna do dirty build? (Y/N): " build_type
  if [[ $build_type == "N" || $build_type == "n" ]]; then
  echo Deleting out directory and doing clean Build
  rm -rf out && mkdir -p out
  fi
  if [[ $build_type == "Y" || $build_type == "y" ]]; then
  echo Warning :- Doing dirty build
  fi
  if ! [[ $build_type == "Y" || $build_type == "y" ]]; then
  if ! [[ $build_type == "N" || $build_type == "n" ]]; then
  echo Invalid Input , Read carefully before typing
  echo Trying to restart script
  . build.sh && exit
  fi
  fi

  # Build the kernel
  make -j$(nproc --all) O=out ARCH=arm64 spaced_defconfig

PATH="${PWD}/clang/bin:${PATH}:${PWD}/los-4.9-32/bin:${PATH}:${PWD}/los-4.9-64/bin:${PATH}" \
make -j$(nproc --all)   O=out \
                        ARCH=arm64 \
                        CC="clang" \
                        CLANG_TRIPLE=aarch64-linux-gnu- \
                        CROSS_COMPILE="${PWD}/los-4.9-64/bin/aarch64-linux-android-" \
                        CROSS_COMPILE_ARM32="${PWD}/los-4.9-32/bin/arm-linux-androideabi-" \
                        LD=ld.lld \
                        AS=llvm-as \
                        AR=llvm-ar \
                        NM=llvm-nm \
                        OBJCOPY=llvm-objcopy \
                        CONFIG_NO_ERROR_ON_MISMATCH=y 2>&1 | tee build.log
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
zip -r9 Nebula-${TANGGAL}.zip *
curl -L bashupload.com -T Nebula-${TANGGAL}.zip
cd ../
fi
}

# Run functions
compile
zupload