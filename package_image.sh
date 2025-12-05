#!/bin/bash
set -e

# Check if running inside Docker container
if [ ! -f /.dockerenv ]; then
    echo "Not running in Docker. Re-launching inside Docker container..."
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    # Use absolute path for the script to ensure it runs correctly inside the container
    # since PWD is mounted to the same path.
    SCRIPT_ABS_PATH="$(cd "$(dirname "$0")"; pwd)/$(basename "$0")"
    # This script requires root privileges inside the container
    export RUN_AS_ROOT=true
    exec "$SCRIPT_DIR/run_docker.sh" "$SCRIPT_ABS_PATH" "$@"
fi

# Script to package Kernel and Rootfs into a bootable QCOW2 image
# Requires: qemu-img, extlinux (syslinux), losetup, fdisk, mkfs.ext4

ROOT_DIR=$(pwd)
KERNEL="build/linux/bzImage"
ROOTFS_CPIO="build/buildroot/buildroot-2019.02.5/output/images/rootfs.cpio"
OUTPUT="build/gns3_base.qcow2"
MBR_BIN="/usr/lib/syslinux/mbr/mbr.bin"

# Force repackage buildroot existing rootfs (output/target folder) to cpio
# Ensure latest rootfs is used
if [ -d "build/buildroot/buildroot-2019.02.5/output/target" ]; then
    echo "Packaging latest Buildroot rootfs to cpio..."
    cd build/buildroot/buildroot-2019.02.5/output/target
    find . | cpio -o --format=newc > ../images/rootfs.cpio
    cd $ROOT_DIR
    echo "Rootfs cpio updated."
else
    echo "Buildroot target directory not found, exiting."
    exit 1
fi

# Check dependencies
for cmd in qemu-img extlinux losetup fdisk mkfs.ext4; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed."
        exit 1
    fi
done

# Check artifacts
if [ ! -f "$KERNEL" ]; then
    echo "Error: Kernel $KERNEL not found. Please run build_kernel.sh first."
    exit 1
fi

if [ ! -f "$ROOTFS_CPIO" ]; then
    echo "Error: Rootfs cpio $ROOTFS_CPIO not found. Please run build_rootfs.sh first."
    exit 1
fi

if [ ! -f "$MBR_BIN" ]; then
    echo "Error: MBR binary $MBR_BIN not found. Please install syslinux."
    # Try alternative location
    MBR_BIN="/usr/lib/EXTLINUX/mbr.bin"
    if [ ! -f "$MBR_BIN" ]; then
         echo "Could not find mbr.bin"
         exit 1
    fi
fi

echo "Creating raw image..."
rm -f $OUTPUT.raw
qemu-img create -f raw $OUTPUT.raw 1G

echo "Partitioning image..."
# Create one partition, bootable, ext4
# n: new, p: primary, 1: partition 1, defaults for start/end, a: bootable, w: write
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $OUTPUT.raw
  n
  p
  1
  
  
  a
  w
EOF

echo "Setting up loop device for partition..."
# Partition 1 starts at sector 2048. 2048 * 512 = 1048576 bytes.
OFFSET=1048576
LOOP_DEV=$(losetup -f --show -o $OFFSET $OUTPUT.raw)
echo "Loop device: $LOOP_DEV"

# Trap to ensure cleanup
cleanup() {
    if [ -n "$LOOP_DEV" ]; then
        echo "Cleaning up loop device..."
        umount build/mnt 2>/dev/null || true
        losetup -d $LOOP_DEV 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "Formatting partition..."
mkfs.ext4 $LOOP_DEV

echo "Mounting partition..."
mkdir -p build/mnt
mount $LOOP_DEV build/mnt

echo "Extracting Rootfs..."
cd build/mnt
# Use -u to overwrite existing files (fixes "newer or same age version exists" errors)
cpio -id -u < ../../$ROOTFS_CPIO
cd ../..

echo "Installing Kernel..."
mkdir -p build/mnt/boot
cp $KERNEL build/mnt/boot/bzImage

echo "Installing Bootloader (Extlinux)..."
extlinux --install build/mnt/boot

echo "Configuring Bootloader..."
cat > build/mnt/boot/extlinux.conf <<EOF
DEFAULT linux
LABEL linux
 SAY Booting GNS3 Base Image...
 KERNEL /boot/bzImage
 APPEND root=/dev/vda1 rw console=ttyS0 console=tty1
EOF

echo "Unmounting..."
umount build/mnt

echo "Detaching loop device..."
losetup -d $LOOP_DEV
LOOP_DEV="" # Clear variable so trap doesn't try to detach again

echo "Installing MBR..."
# Write MBR directly to the start of the raw image file
dd if=$MBR_BIN of=$OUTPUT.raw bs=440 count=1 conv=notrunc

echo "Converting to QCOW2..."
qemu-img convert -f raw -O qcow2 $OUTPUT.raw $OUTPUT
rm $OUTPUT.raw

echo "Success! Bootable image created at $OUTPUT"
echo "You can test it with:"
echo "qemu-system-x86_64 -hda $OUTPUT -nographic"

# Generate .gns3a file for GNS3 registry
echo "Generating GNS3 appliance file..."
IMG_MD5=$(md5sum $OUTPUT | awk '{print $1}')
IMG_SIZE=$(stat -c%s $OUTPUT)
GNS3A_FILE="build/gns3_base_image.gns3a"

# Fix ownership if running as root and ORIGINAL_UID is set
if [ "$(id -u)" -eq 0 ] && [ -n "$ORIGINAL_UID" ]; then
    echo "Fixing ownership of output files..."
    chown $ORIGINAL_UID:$ORIGINAL_GID $OUTPUT $GNS3A_FILE
fi

cat > $GNS3A_FILE <<EOF
{
    "name": "GNS3 Base Image",
    "category": "guest",
    "description": "Custom GNS3 Base Image (Kernel 4.4 + Buildroot)",
    "vendor_name": "Custom",
    "vendor_url": "https://github.com/GNS3/gns3-registry",
    "product_name": "GNS3 Base Image",
    "product_url": "",
    "registry_version": 3,
    "status": "experimental",
    "maintainer": "User",
    "maintainer_email": "user@example.com",
    "usage": "Import this appliance into GNS3.",
    "first_port_name": "eth0",
    "port_name_format": "eth{port1}",
    "qemu": {
        "adapter_type": "virtio-net-pci",
        "adapters": 28,
        "ram": 1024,
        "cpus": 2,
        "hda_disk_interface": "virtio",
        "arch": "x86_64",
        "console_type": "telnet",
        "kvm": "require"
    },
    "images": [
        {
            "filename": "gns3_base.qcow2",
            "version": "1.0",
            "md5sum": "$IMG_MD5",
            "filesize": $IMG_SIZE,
            "download_url": "file://build/gns3_base.qcow2",
            "direct_download_url": "file://build/gns3_base.qcow2"
        }
    ],
    "versions": [
        {
            "name": "1.0",
            "images": {
                "hda_disk_image": "gns3_base.qcow2"
            }
        }
    ]
}
EOF

echo "GNS3 appliance file created at $GNS3A_FILE"
