#!/bin/sh
#https://randomcoderdude.wordpress.com/2013/08/11/controlling-leds-status-in-openwrt/

echo "Turn off trigger"
for p in `find /sys/devices/platform/leds-gpio/leds -name trigger`; do
    echo $p
    echo none > $p
done

echo ""
echo "Set 0 as brightness"
for p in `find /sys/devices/platform/leds-gpio/leds -name brightness`; do
    echo $p
    echo 0 > $p
done