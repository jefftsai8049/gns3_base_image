#!/bin/bash
set -e

# Build script for GNS3 base image
# Includes steps to build buildroot rootfs

BUILD_ROOT_DIR="./build/buildroot"

# Create build directory
mkdir -p $BUILD_ROOT_DIR

# Check if buildroot source is already extracted
if ls -d $BUILD_ROOT_DIR/buildroot-*/ 1> /dev/null 2>&1; then
    echo "Buildroot source already extracted. Skipping copy and extraction."
else
    # Copy buildroot tarball from source folder
    echo "Copying Buildroot source..."
    cp source/buildroot-*.tar.gz $BUILD_ROOT_DIR/
    
    cd $BUILD_ROOT_DIR
    # Extract buildroot tarball
    echo "Extracting Buildroot source..."
    tar -xzf buildroot-*.tar.gz
    rm buildroot-*.tar.gz
    cd - > /dev/null
fi

# Enter buildroot directory
# Find and enter the extracted buildroot directory
BUILD_ROOT_DIR_ROOT=`find $BUILD_ROOT_DIR -maxdepth 1 -type d -name "buildroot-*" | head -n 1`
echo $BUILD_ROOT_DIR_ROOT
cd $BUILD_ROOT_DIR_ROOT
ls 

# Fix for GCC 14+ build issues with older packages (like host-fakeroot)
# export HOSTCFLAGS="-O2 -Wno-incompatible-pointer-types"

# Configure buildroot
echo "Configuring Buildroot..."

# Hack: Ensure output directory exists and .br-external.mk is created manually
# This avoids "No rule to make target ... output/.br-external.mk" error
mkdir -p output
support/scripts/br2-external -m -o output/.br-external.mk

make qemu_x86_64_defconfig

# Customize for Linux Kernel 4.4.x (CIP) and minimal rootfs
# We need to ensure the toolchain uses headers compatible with our 4.4 kernel
# Disable Linux Kernel build (we build it separately)
sed -i 's/BR2_LINUX_KERNEL=y/# BR2_LINUX_KERNEL is not set/g' .config

echo "Applying configuration for Kernel 4.4.x..."
cat >> .config <<END_CONFIG
BR2_KERNEL_HEADERS_4_4=y
BR2_TARGET_ROOTFS_CPIO=y
BR2_TARGET_ROOTFS_EXT2=y
BR2_TARGET_GENERIC_GETTY_PORT="ttyS0"
BR2_TARGET_GENERIC_GETTY_BAUDRATE_115200=y
END_CONFIG

# Update configuration
make olddefconfig

# Build buildroot
echo "Building Buildroot..."

# Hack: Extract host-fakeroot and patch it to fix _STAT_VER issue on newer glibc
# echo "Patching host-fakeroot..."
# make host-fakeroot-extract
# find output/build/host-fakeroot-1.20.2 -name "libfakeroot.c" -exec sed -i '1i #ifndef _STAT_VER\n#define _STAT_VER 0\n#endif' {} +

make -j$(nproc)
