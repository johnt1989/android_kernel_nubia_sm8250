#!/bin/bash

# Variables
DIR=`readlink -f .`;
PARENT_DIR=`readlink -f ${DIR}/..`;

CHIPSET_NAME=kona
ARCH=arm64

export ARCH=arm64
export SUBARCH=arm64
export PLATFORM_VERSION=11.0.0
export ANDROID_MAJOR_VERSION=r
export BUILD_CROSS_COMPILE=$PARENT_DIR/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export KERNEL_LLVM_BIN=$PARENT_DIR/llvm-arm-toolchain-ship-10.0/bin/clang
export CLANG_PATH=$PARENT_DIR/llvm-arm-toolchain-ship-10.0/bin/
export PATH=${CLANG_PATH}:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export KERNEL_MAKE_ENV=""

toolchain()
{
  if [ ! -d $PARENT_DIR/aarch64-linux-android-4.9 ]; then
    git clone --branch android-9.0.0_r59 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 $PARENT_DIR/aarch64-linux-android-4.9
  fi
}

llvm()
{
  if [ ! -d $PARENT_DIR/llvm-arm-toolchain-ship-10.0 ]; then
    git clone https://github.com/proprietary-stuff/llvm-arm-toolchain-ship-10.0 $PARENT_DIR/llvm-arm-toolchain-ship-10.0
  fi
}

clean()
{
  echo "***** Cleaning in Progress *****"
  make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE clean 
  make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE mrproper
  [ -d "out" ] && rm -rf out
  echo "***** Cleaning Done *****"
}

build()
{
  echo "***** Compiling kernel *****"
  [ ! -d "out" ] && mkdir out
  make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE nx659j_defconfig
  make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE

  [ -e out/arch/arm64/boot/Image.gz ] && cp out/arch/arm64/boot/Image.gz $(pwd)/out/Image.gz
  if [ -e out/arch/arm64/boot/Image.gz-dtb ]; then
    cp out/arch/arm64/boot/Image.gz-dtb $(pwd)/out/Image.gz-dtb
  fi
}

anykernel3()
{
  if [ ! -d $PARENT_DIR/AnyKernel3 ]; then
    git clone https://github.com/osm0sis/AnyKernel3 $PARENT_DIR/AnyKernel3
  fi
  [ -e $PARENT_DIR/nx659j_kernel_kernel.zip ] && rm $PARENT_DIR/nx659j_kernel.zip
  if [ -e out/arch/arm64/boot/Image.gz-dtb ]; then
    cp out/arch/arm64/boot/Image.gz-dtb $PARENT_DIR/AnyKernel3/zImage
  elif [ -e out/arch/arm64/boot/Image.gz ]; then
    cp out/arch/arm64/boot/Image.gz $PARENT_DIR/AnyKernel3/zImage
  fi
  cd $PARENT_DIR/AnyKernel3
  git reset --hard
  sed -i "s/ExampleKernel by osm0sis/NX659J kernel by Doc714/g" anykernel.sh
  sed -i "s/=maguro/=NX659J/g" anykernel.sh
  sed -i "s/=toroplus/=/g" anykernel.sh
  sed -i "s/=toro/=/g" anykernel.sh
  sed -i "s/=tuna/=/g" anykernel.sh
  sed -i "s/omap\/omap_hsmmc\.0\/by-name\/boot/soc\/1d84000\.ufshc\/by-name\/boot/g" anykernel.sh
  sed -i "s/backup_file/#backup_file/g" anykernel.sh
  sed -i "s/replace_string/#replace_string/g" anykernel.sh
  sed -i "s/insert_line/#insert_line/g" anykernel.sh
  sed -i "s/append_file/#append_file/g" anykernel.sh
  sed -i "s/patch_fstab/#patch_fstab/g" anykernel.sh
  zip -r9 $PARENT_DIR/NX659J_kernel.zip * -x .git README.md *placeholder
  cd $DIR
}

toolchain
llvm
clean
build
anykernel3