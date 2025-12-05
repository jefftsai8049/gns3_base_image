# GNS3 Base Image Builder with CPSS Simulator

This project provides a comprehensive toolset to build a custom Linux-based GNS3 appliance with integrated CPSS (Common Platform Software Stack) simulator for network device emulation.

## Features

- **Custom Linux Kernel 4.4.302-cip77** with VirtIO support
- **Buildroot-based rootfs** with networking tools (bash, tcpdump, bridge-utils)
- **CPSS Simulator** (appDemo) for Marvell switch emulation
- **28-port network interface** support (xCat3 configuration)
- **SLAN TUN/TAP bridges** for packet forwarding between QEMU and CPSS
- **VirtIO paravirtualization** for high-performance I/O
- **Automatic startup scripts** for SLAN bridges and CPSS initialization
- **Docker-based build environment** with auto-wrapper scripts

## Prerequisites

*   **Docker**: Required for the build environment
*   **QEMU**: Required for running the images (`qemu-system-x86_64`)
*   **wget**: Required for downloading source files
*   **CPSS Source**: Place `CPSS-4.3.17_015_Source_Git.tar` in `source/` directory

## Usage Instructions

### 1. Download Sources

Download the Linux Kernel and Buildroot source tarballs:

```bash
./download_source.sh
```

**Important**: Manually place the CPSS source tarball:
```bash
# Download CPSS-4.3.17_015_Source_Git.tar from Marvell
cp CPSS-4.3.17_015_Source_Git.tar source/
```

### 2. Build Docker Environment

Create the Docker image used for building:

```bash
./build_docker.sh
```

### 3. Build Kernel

Build the Linux kernel with VirtIO and networking support:

```bash
./build_kernel.sh
```

**Kernel Features:**
- VirtIO drivers (virtio-net, virtio-blk) for high performance
- TUN/TAP support for virtual network interfaces
- Bridge, VLAN, STP support for network switching
- POSIX IPC support for CPSS

Build output: `build/linux/bzImage`

### 4. Build Rootfs

Build the Buildroot-based root filesystem:

```bash
./build_rootfs.sh
```

**Rootfs Features:**
- glibc toolchain
- Bash shell
- Networking tools: tcpdump, libpcap, bridge-utils
- 300MB ext2 filesystem
- Serial console on ttyS0

Build output: `build/buildroot/buildroot-2019.02.5/output/images/rootfs.cpio`

### 5. Build CPSS Simulator

Build and install the CPSS appDemo simulator:

```bash
./build_cpss_sim.sh
```

**CPSS Installation:**
- Compiles appDemo for x86_64 simulation
- Installs to `/usr/bin/appDemo` in rootfs
- Copies xCat3 configuration files to `/etc/cpss/`
- Installs SLAN connector utilities
- Installs S99local init script for automatic startup

Build output: `build/cpss/compilation_root/HEAD/sim64_DX/appDemo`

### 6. Package Image

Package everything into a bootable QCOW2 image and GNS3 appliance:

```bash
./package_image.sh
```

**Output:**
- `build/gns3_base.qcow2` - Bootable disk image with VirtIO support
- `build/gns3_base_image.gns3a` - GNS3 appliance descriptor

**Image Configuration:**
- Disk interface: VirtIO (root=/dev/vda1)
- Network adapters: 28x virtio-net-pci (eth0-eth27)
- RAM: 1024MB
- CPUs: 2
- Console: Telnet

> **Note**: All build scripts automatically detect Docker and re-launch inside the container if needed. No manual `docker run` required!

### 7. Test with QEMU

Test the image locally before importing to GNS3:

```bash
./run_qemu.sh [EXTRANET_INDEX]
```

**Parameters:**
- `EXTRANET_INDEX` (optional): Which interface gets internet access (default: 0)
- Example: `./run_qemu.sh 3` makes eth3 the internet-facing interface

**Network Configuration:**
- One interface with internet (NAT) access
- 27 isolated interfaces for inter-device communication
- All using virtio-net-pci for high performance

## GNS3 Integration

### Import Appliance

1. Copy files to GNS3 server:
   ```bash
   scp build/gns3_base.qcow2 gns3-server:/path/to/GNS3/images/QEMU/
   scp build/gns3_base_image.gns3a gns3-server:/path/to/
   ```

2. In GNS3 GUI:
   - File → Import appliance
   - Select `gns3_base_image.gns3a`
   - Choose the uploaded `gns3_base.qcow2` image

### Appliance Configuration

**Network:**
- 28 Ethernet ports (eth0-eth27)
- VirtIO paravirtualized NICs
- Maps to CPSS ports via SLAN bridges

**CPSS Port Mapping:**
```
eth0 ↔ br0 ↔ tap0 ↔ slan00 ↔ CPSS port0
eth1 ↔ br1 ↔ tap1 ↔ slan01 ↔ CPSS port1
...
eth27 ↔ br27 ↔ tap27 ↔ slan27 ↔ CPSS port27
```

### Automatic Startup

The image automatically starts SLAN bridges on boot via `/etc/init.d/S99local`:
1. Starts `slanConnector` daemon
2. Creates 28 TAP interfaces (tap0-tap27)
3. Creates 28 bridges (br0-br27)
4. Bridges each eth interface to corresponding TAP interface
5. Ready for CPSS simulator to use

## CPSS Simulator Usage

### Manual Start

If CPSS doesn't auto-start, run manually:

```bash
# Inside the GNS3 appliance console
/usr/bin/appDemo -i /etc/cpss/xCat3_A1_wm_28G.ini -config_file /etc/cpss/cpss_init.cfg
```

### CPSS Configuration Files

- **xCat3_A1_wm_28G.ini**: Device configuration (28-port xCat3 switch)
- **cpss_init.cfg**: Initialization commands (`cpssinitsystem 19,2,0`)
- **registerFiles/**: Chip register definitions

### CPSS Console

Once started, you'll have access to the CPSS CLI:
```
console>
```

Use CPSS commands to configure the simulated switch.
Run command cpssinitsystem to initialize the simulator.
```
cpssinitsystem 19,2,0
```

## Advanced Configuration

### Modify CPSS Configuration

Edit configuration files:
```bash
vim config/cpss/xCat3_A1_wm_28G.ini
```

Rebuild:
```bash
./build_cpss_sim.sh
./package_image.sh
```

### Change Number of Ports

1. Update `build_cpss_sim.sh`: Change `SLAN_IFACES_NUM=8` to desired count
2. Update `local_package/slanTunTap/slanBridge.sh`: Change loop range `{0..27}`
3. Update `config/cpss/xCat3_A1_wm_28G.ini`: Add/remove port mappings
4. Update `package_image.sh`: Change `"adapters": 28` in .gns3a file

### Performance Tuning

**VirtIO vs e1000:**
- Current: VirtIO (10+ Gbps, low CPU)
- Alternative: e1000 (1 Gbps, better compatibility)
- Change in `package_image.sh`: `"adapter_type": "e1000"`

**Disk Interface:**
- Current: VirtIO (fast)
- Alternative: IDE (slower, universal)
- Change in `package_image.sh`: `"hda_disk_interface": "ide"` and boot param `root=/dev/sda1`

## Troubleshooting

### MD5 Checksum Mismatch in GNS3

The `.gns3a` file was generated before the image was modified. Regenerate:
```bash
./package_image.sh
```

Then re-upload `gns3_base.qcow2` to GNS3 server.

### Network Interfaces Not Working

1. Check VirtIO drivers: `lsmod | grep virtio`
2. Check bridges: `brctl show`
3. Check TAP interfaces: `ifconfig tap0`
4. Restart SLAN: `/etc/init.d/S99local start`

## Technical Details

### Kernel Configuration

- **Architecture**: x86_64
- **Version**: 4.4.302-cip77 (CIP Long Term Support)
- **Key Features**:
  - CONFIG_VIRTIO=y, CONFIG_VIRTIO_NET=y, CONFIG_VIRTIO_BLK=y
  - CONFIG_TUN=y, CONFIG_BRIDGE=y, CONFIG_VLAN_8021Q=y
  - CONFIG_POSIX_MQUEUE=y, CONFIG_FUTEX=y, CONFIG_SYSVIPC=y

### Buildroot Configuration

- **Toolchain**: glibc (for better CPSS compatibility)
- **Kernel Headers**: 4.4.x
- **Shell**: Bash
- **Packages**: tcpdump, libpcap, bridge-utils
- **Filesystem**: ext2 (300MB), CPIO for initramfs

### CPSS Build

- **Target**: sim64 (x86_64 simulation)
- **Family**: DX (DxCh family)
- **Debug**: Enabled (D_ON)
- **Shared Memory**: Enabled (CONFIG_SHARED_MEMORY=y for POSIX_SEM)

## Build Scripts Reference

| Script | Purpose | Output |
|--------|---------|--------|
| `download_source.sh` | Download kernel and Buildroot sources | `source/*.tar.gz` |
| `build_docker.sh` | Build Docker environment | Docker image |
| `build_kernel.sh` | Compile Linux kernel | `build/linux/bzImage` |
| `build_rootfs.sh` | Build Buildroot rootfs | `build/buildroot/.../rootfs.cpio` |
| `build_cpss_sim.sh` | Build and install CPSS | `appDemo` in rootfs |
| `package_image.sh` | Create bootable image | `build/gns3_base.qcow2` |
| `run_qemu.sh` | Test image locally | Runs QEMU |

All scripts support Docker auto-wrapper (automatically run inside container if executed from host).
