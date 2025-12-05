#!/bin/bash

# Default Extranet Interface is eth0 (Index 0)
EXTRANET_INDEX=${1:-0}

echo "Starting QEMU..."
echo "Extranet (Internet) assigned to: eth$EXTRANET_INDEX"
echo "Other interfaces are isolated (Internal only)."

# Build QEMU arguments
NET_ARGS=""
PREFIX_MAC="00:50:43"
for i in {0..27}; do
    HEX_ID=$(printf "%02x" $i)
    if [ "$i" -eq "$EXTRANET_INDEX" ]; then
        # Unrestricted User Network (NAT/Internet)
        NET_ARGS="$NET_ARGS -netdev user,id=net$i -device virtio-net-pci,netdev=net$i,mac=${PREFIX_MAC}:12:34:$HEX_ID"
    else
        # Restricted User Network (No Internet, just local DHCP)
        NET_ARGS="$NET_ARGS -netdev user,id=net$i,restrict=y -device virtio-net-pci,netdev=net$i,mac=52:54:00:12:34:$HEX_ID"
    fi
done

MEMORY_SIZE=1024  # in MB
IMAGE_PATH="build/gns3_base.qcow2"
echo "QEMU Network Configuration:"
for i in {0..27}; do
    if [ "$i" -eq "$EXTRANET_INDEX" ]; then
        echo "  eth$i: Unrestricted (Internet access)"
    else
        echo "  eth$i: Restricted (No Internet)"
    fi
done
echo "Using disk image: $IMAGE_PATH"
echo "Allocating memory: ${MEMORY_SIZE}MB"
qemu-system-x86_64 -m ${MEMORY_SIZE} -hda ${IMAGE_PATH} -nographic $NET_ARGS
