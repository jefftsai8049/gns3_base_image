#!/bin/bash
CONTAINER_NAME=gns3_base_image_builder
CURRENT_USER_UID=`id -u`
CURRENT_USER_GID=`id -g`

# Run docker
docker run -it --rm --privileged \
           --name ${CONTAINER_NAME}_$(date +%s) \
           -u $CURRENT_USER_UID:$CURRENT_USER_GID \
           -v /etc/group:/etc/group:ro \
           -v /etc/passwd:/etc/passwd:ro \
           -v /etc/sudoers:/etc/sudoers:ro \
           -v /etc/shadow:/etc/shadow:ro \
           -v $PWD:$PWD \
           -v $HOME:$HOME \
           -w $PWD \
          gns3_base_image_builder \
           /bin/bash