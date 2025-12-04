#!/bin/bash
slanConnector -D
for i in {0..7}
do
    slanTunTapLinux -D -n slan0$i
    ifconfig tap$i up

    ip link add name br$i type bridge
    ip link set dev br$i up
    ip link set dev eth$i master br$i
    ip link set dev tap$i master br$i
done
