#!/bin/bash
# This script runs QEMU with the specified base image for GNS3 with x86-64 architecture.
# QCow2 UEFI/GPT Bootable disk image
# Ubuntu 20.04 LTS Focal Fossa x86-64 Cloud Image
# Source: https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
# Default Username: ubuntu
# Default Password: ubuntu

QEMU_PATH="/usr/bin/qemu-system-x86_64"
BASE_IMAGE="./image/focal-server-cloudimg-amd64.img" # Ensure this file exists
RAM_SIZE="4096"

# For x86_64, we typically don't need the specific ARM UEFI BIOS path or machine type 'virt' in the same way.
# Standard PC architecture is usually sufficient, or q35.
MACHINE_TYPE="q35"

# Check for KVM
if [ -e /dev/kvm ]; then
    echo "KVM detected, enabling hardware acceleration."
    CPU_TYPE="host"
    ACCEL="-enable-kvm"
else
    echo "KVM not detected, falling back to software emulation (TCG)."
    CPU_TYPE="qemu64"
    ACCEL=""
fi

# Update the QEMU command for x86_64
QEMU_CMD="$QEMU_PATH -M $MACHINE_TYPE -cpu $CPU_TYPE -m $RAM_SIZE -drive file=$BASE_IMAGE,format=qcow2,if=virtio -net nic,model=virtio -net user -nographic $ACCEL"

# Execute the command
echo "Executing: $QEMU_CMD"
exec $QEMU_CMD
