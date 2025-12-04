# GNS3 Base Image Builder

This project provides a set of tools to build a custom Linux kernel and rootfs (using Buildroot) for GNS3.

## Prerequisites

*   **Docker**: Required for the build environment.
*   **QEMU**: Required for running the images (`qemu-system-x86_64`).
*   **wget**: Required for downloading source files.

## Directory Structure

*   `source/`: Stores downloaded source tarballs (Kernel, Buildroot).
*   `build/`: Working directory for builds (Kernel, Rootfs).
*   `docker/`: Docker build environment configuration.
*   `image/`: Directory for storing disk images (e.g., Ubuntu Cloud Image).

## Usage Instructions

### 1. Download Sources

Download the Linux Kernel and Buildroot source tarballs.

```bash
./download_source.sh
```

### 2. Build Docker Environment

Create the Docker image used for building the kernel and rootfs.

```bash
./build_docker.sh
```

### 3. Build Kernel & Rootfs

Build scripts will automatically run inside Docker if not already in the container:

```bash
# Build the Linux Kernel
./build_kernel.sh

# Build the Root Filesystem
./build_rootfs.sh
```

> **Note**: The scripts automatically detect if they're running outside Docker and will re-launch themselves inside the container. You can also manually enter the container with `./run_docker.sh` if needed.

The build artifacts
*   Kernel: `build/bzImage`
*   Rootfs: `build/buildroot/output/images/rootfs.cpio` (or similar, depending on config)

### 4. Package Image & Generate GNS3 Appliance

Package the built kernel and rootfs into a bootable QCOW2 image and generate a GNS3 appliance file:

```bash
./package_image.sh
```

> **Note**: This script automatically runs with root privileges inside Docker when needed for operations like `losetup` and `mount`.

This will create:
*   **Disk Image**: `build/gns3_base.qcow2`
*   **GNS3 Appliance**: `build/gns3_base_image.gns3a`

You can verify the image by running:
```bash
qemu-system-x86_64 -hda build/gns3_base.qcow2 -nographic
```


