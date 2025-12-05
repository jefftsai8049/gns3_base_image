#!/bin/bash
slanConnector -D
for i in {0..27}
do
    ID=$(printf "%02d" $i)
    slanTunTapLinux -D -n slan$ID
    ifconfig tap$i up
    ifconfig eth$i up

    ip link add name br$i type bridge
    ip link set dev br$i up
    ip link set dev eth$i master br$i
    ip link set dev tap$i master br$i
done
