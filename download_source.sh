# This script downloads the QEMU aarch64 base image source for GNS3.
# Include Linux kernel source, rootfs and other necessary components.
#!/bin/bash

# Help message
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0"
    echo "This script downloads the QEMU aarch64 base image source for GNS3."
    echo "  -c : Clean existing downloaded files."
    exit 0
fi

# Version information
KERNEL_URL="wget https://git.kernel.org/pub/scm/linux/kernel/git/cip/linux-cip.git/snapshot/linux-cip-4.4.302-cip77.tar.gz"
ROOTFS_URL="https://buildroot.org/downloads/buildroot-2019.02.5.tar.gz"

# Option "-c" to clean existing files
if [ "$1" == "-c" ]; then
    echo "Cleaning existing files..."
    rm -rf linux-$LINUX_VERSION linux-$LINUX_VERSION.tar.xz
    echo "Cleanup completed."
    exit 0
fi

# Create a directory for downloads
DOWNLOAD_DIR="source"
mkdir -p $DOWNLOAD_DIR
cd $DOWNLOAD_DIR

# Download Linux kernel source
# Check if Linux kernel source is already downloaded
# Extract version from URL
LINUX_VERSION=$(echo $KERNEL_URL | grep -oP 'linux-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -d "linux-$LINUX_VERSION" ]; then
    echo "Linux kernel source version $LINUX_VERSION already exists. Skipping download."
else
    echo "Linux kernel source version $LINUX_VERSION not found. Proceeding to download."
    echo "Downloading Linux kernel source..."
    wget $KERNEL_URL -O linux-$LINUX_VERSION.tar.xz
fi

# Download root filesystem
ROOTFS_VERSION=$(echo $ROOTFS_URL | grep -oP 'buildroot-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -d "buildroot-$ROOTFS_VERSION" ]; then
    echo "Root filesystem version $ROOTFS_VERSION already exists. Skipping download."
else
    echo "Root filesystem version $ROOTFS_VERSION not found. Proceeding to download."
    echo "Downloading root filesystem..."
    wget $ROOTFS_URL -O buildroot-$ROOTFS_VERSION.tar.gz
fi
