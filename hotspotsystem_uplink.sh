#!/bin/bash

# Get hotspot info
NASID=`uci get chilli.@chilli[0].radiusnasid`
WLAN=`ifconfig | grep wl | sort | head -1 | cut -d " " -f1`
WLANMAC=`ifconfig \$WLAN | awk '"'"'/HWaddr/ { print $5 }'"'"' | sed '"'"'s/:/-/g'"'"'`
UP=`uptime|sed "s/ /\%20/g"|sed "s/:/\%3A/g"|sed "s/,/\%2C/g"`

echo "Printing base information"
echo NASID=$NASID
echo WLAN=$WLAN WLANMAC=$WLANMAC
uptime
echo UP=$UP

# Perform uplink, and get result
/usr/bin/wget http://tech.hotspotsystem.com/up.php?mac=$WLANMAC\&nasid=$NASID\&os_date=OpenWrt\&uptime=\$UP --output-document /tmp/up.result

# See file commands
echo -e "Content of: /tmp/up.result\n"
cat /tmp/up.result

# Execute possible commands
chmod 755 /tmp/up.result
/tmp/up.result


