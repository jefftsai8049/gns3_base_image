#!/bin/bash
ROOT_DIR="${PWD}"

# Check if running inside Docker container
if [ ! -f /.dockerenv ]; then
    echo "Not running in Docker. Re-launching inside Docker container..."
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    # Use absolute path for the script to ensure it runs correctly inside the container
    # since PWD is mounted to the same path.
    SCRIPT_ABS_PATH="$(cd "$(dirname "$0")"; pwd)/$(basename "$0")"
    exec "$SCRIPT_DIR/run_docker.sh" "$SCRIPT_ABS_PATH" "$@"
fi

CPSS_SRC_DIR="${ROOT_DIR}/build/cpss"

# Check if CPSS source code directory exists
# If not, extract it from the tarball
CPSS_VERSION="4.3.17_015"
if [ ! -d $CPSS_SRC_DIR ]; then
    if [ -f "./source/CPSS-${CPSS_VERSION}_Source_Git.tar" ]; then
        echo "Extracting CPSS source code..."
        mkdir -p $CPSS_SRC_DIR
        tar -xf ./source/CPSS-${CPSS_VERSION}_Source_Git.tar -C $CPSS_SRC_DIR --strip-components=1
    else
        echo "Error: CPSS source code directory and tarball not found."
        echo "Please download CPSS source code tarball and place it in the 'source' directory."
        exit 1
    fi
fi

cd $CPSS_SRC_DIR
git checkout CPSS_${CPSS_VERSION}

# Show this script usage message
function show_usage_msg {
    echo "Usage: ${0##*/} [-h] [-c]"
    echo "  [-h]: Show usage message"
    echo "  [-c]: Clear all before build"
}

# Optional flags
OPT_ARG_CLEAN=false

#----------------
# Parse arugments
#----------------
while [ $# -gt 0 ]; do
    case "$1" in
        # Parege optional arguments
        -c) OPT_ARG_CLEAN=true ;;

        # Parse help message and default
        -h) show_usage_msg; exit 0 ;;
         *) echo "*************************"
            echo "Error!!! Unknown argument"
            echo "*************************";
            show_usage_msg;
            exit 1 ;;
     esac
     shift
done

export ARCH=x86
export DEBUG_INFO=D_ON
export CPSS_USER_CFLAGS="-Wno-unused-parameter"
make -j$(nproc) TARGET=sim64 FAMILY=DX appDemo

# Install appDemo to rootfs of buildroot
CPSS_BRANCH_NOW=`git rev-parse --abbrev-ref HEAD`
BUILDROOT_ROOTFS_DIR=`find ${ROOT_DIR}/build/buildroot -maxdepth 2 -type d -name "output"`/target
echo "CPSS branch: $CPSS_BRANCH_NOW"
echo "Buildroot rootfs dir: $BUILDROOT_ROOTFS_DIR"
echo "Installing appDemo to buildroot rootfs..."
cp ./compilation_root/$CPSS_BRANCH_NOW/sim64_DX/appDemo $BUILDROOT_ROOTFS_DIR/usr/bin/
echo "Installation CPSS done."

# Copy CPSS simulation configuration files to rootfs of buildroot
CPSS_CONFIG_SRC_DIR="${PWD}/../../config/cpss"
if [ ! -d $CPSS_CONFIG_SRC_DIR ]; then
    echo "Error: CPSS configuration files directory not found at: $CPSS_CONFIG_SRC_DIR"
    exit 1
fi
echo "Copying CPSS simulation configuration files to buildroot rootfs..."
mkdir -p $BUILDROOT_ROOTFS_DIR/etc/cpss
cp $CPSS_CONFIG_SRC_DIR/* $BUILDROOT_ROOTFS_DIR/etc/cpss/
cp $CPSS_SRC_DIR/simulation/registerFiles $BUILDROOT_ROOTFS_DIR/etc/cpss/registerFiles -r
echo "Copying CPSS simulation configuration files done."

# Install SLAN connector to rootfs of buildroot
SLAN_SRC="${ROOT_DIR}/local_package/slanTunTap"
SLAN_IFACES_NUM=8
if [ ! -d $SLAN_SRC ]; then
    echo "Error: SLAN connector source directory not found at: $SLAN_SRC"
    exit 1
fi

echo "Installing SLAN connector to buildroot rootfs..."
cp $SLAN_SRC/* $BUILDROOT_ROOTFS_DIR/usr/bin/
echo "Create SLAN connector configuration file..."
mkdir -p $BUILDROOT_ROOTFS_DIR/etc/cpss
SLAN_CONFIG_FILE=$BUILDROOT_ROOTFS_DIR/usr/bin/slan.cfg
# Generate SLAN interface names based on SLAN_IFACES_NUM
rm $SLAN_CONFIG_FILE 2>/dev/null
for i in $(seq 0 $((SLAN_IFACES_NUM - 1))); do
    if [ $i -lt $((SLAN_IFACES_NUM - 1)) ]; then
        echo -n "slan$(printf "%02d" $i), " >> $SLAN_CONFIG_FILE
    else
        echo -n "slan$(printf "%02d" $i)" >> $SLAN_CONFIG_FILE
    fi
done
echo "SLAN connector configuration file created at: $SLAN_CONFIG_FILE"
chmod +x $BUILDROOT_ROOTFS_DIR/usr/bin/slan*
echo "Installation SLAN connector done."

echo "Copy S99local to buildroot rootfs..."
cp ${ROOT_DIR}/config/rootfs/S99local $BUILDROOT_ROOTFS_DIR/etc/init.d/
chmod +x $BUILDROOT_ROOTFS_DIR/etc/init.d/S99local
echo "Copy S99local done."

echo "Build and installation completed successfully."
