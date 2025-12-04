#!/bin/bash
CONTAINER_NAME=gns3_base_image_builder

# Determine original user
if [ -n "$SUDO_UID" ]; then
    ORIGINAL_UID=$SUDO_UID
    ORIGINAL_GID=$SUDO_GID
else
    ORIGINAL_UID=$(id -u)
    ORIGINAL_GID=$(id -g)
fi

# Auto-detect if we need to run as root (e.g. for package_image.sh which uses losetup)
if [[ "$@" == *"package_image.sh"* ]]; then
    RUN_AS_ROOT=true
fi

# Determine container user
if [ "$RUN_AS_ROOT" = "true" ]; then
    CONTAINER_USER="0:0"
else
    CONTAINER_USER="$ORIGINAL_UID:$ORIGINAL_GID"
fi

# Run docker
docker run -it --rm --privileged \
           --name ${CONTAINER_NAME}_$(date +%s) \
           -u $CONTAINER_USER \
           -e ORIGINAL_UID=$ORIGINAL_UID \
           -e ORIGINAL_GID=$ORIGINAL_GID \
           -v /etc/group:/etc/group:ro \
           -v /etc/passwd:/etc/passwd:ro \
           -v /etc/sudoers:/etc/sudoers:ro \
           -v /etc/shadow:/etc/shadow:ro \
           -v $PWD:$PWD \
           -v $HOME:$HOME \
           -w $PWD \
          gns3_base_image_builder "$@"
