#!/bin/bash

# Build script for GNS3 base image
# Includes steps to build Linux kernel

# Check if running inside Docker container
if [ ! -f /.dockerenv ]; then
    echo "Not running in Docker. Re-launching inside Docker container..."
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    # Use absolute path for the script to ensure it runs correctly inside the container
    # since PWD is mounted to the same path.
    SCRIPT_ABS_PATH="$(cd "$(dirname "$0")"; pwd)/$(basename "$0")"
    exec "$SCRIPT_DIR/run_docker.sh" "$SCRIPT_ABS_PATH" "$@"
fi

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

# Enable TUN/TAP, Bridge, and other required features for CPSS
echo "Enabling TUN/TAP, Bridge support for CPSS..."
cat >> .config <<END_CONFIG
# Network support for GNS3
CONFIG_TUN=y
CONFIG_BRIDGE=y
CONFIG_VLAN_8021Q=y
CONFIG_STP=y
CONFIG_BRIDGE_IGMP_SNOOPING=y
CONFIG_LLC=y
END_CONFIG

# Update config
make olddefconfig

echo "Building kernel with $(nproc) parallel jobs..."
make -j$(nproc)

# Copy the built kernel to the build directory
echo "Copying built kernel..."
cp arch/x86/boot/bzImage ../bzImage

echo ""
echo "=========================================="
echo "Kernel build complete!"
echo "Output: build/linux/bzImage"
echo "=========================================="
