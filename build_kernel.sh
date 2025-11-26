#!/bin/bash

# Build script for GNS3 base image
# Includes steps to build Linux kernel

# Create build directory
BUILD_DIR="./build"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Copy Linux kernel source from source folder
mkdir -p linux
# Copy the source code tarball
echo "Copying Linux kernel source..."
# If destination tarball exists, skip to copy
if ls ./linux/linux-*.tar* 1> /dev/null 2>&1; then
    echo "Linux kernel source tarball already exists in build directory. Skipping copy."
else
    cp ../source/linux-*tar* ./linux/
fi
cd linux
# Extract the source code
echo "Extracting Linux kernel source..."
# If already extracted, skip extraction
if ls -d linux-*/ 1> /dev/null 2>&1; then
    echo "Linux kernel source already extracted. Skipping extraction."
else
    tar -xf linux-*.tar*
fi

# Enter the Linux kernel source directory
ls
cd linux-*/
pwd
# Build Linux kernel
make defconfig
make -j$(nproc)
# Copy the built kernel to the build directory
cp arch/x86/boot/bzImage ../bzImage

# # Optional: Test boot with QEMU
# qemu-system-x86_64 -kernel ../bzImage -append "console=ttyS0" -nographic
