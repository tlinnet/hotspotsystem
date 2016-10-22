#!/bin/bash

# Get hotspot info
NASID=`uci get chilli.@chilli[0].radiusnasid`
WLAN=`ifconfig | grep wl | sort | head -1 | cut -d " " -f1`
WLANMAC=`ifconfig \$WLAN | awk '"'"'/HWaddr/ { print $5 }'"'"' | sed '"'"'s/:/-/g'"'"'`
UPTIME=`uptime`
UP=`echo $UPTIME | sed "s/ /\%20/g" | sed "s/:/\%3A/g" | sed "s/,/\%2C/g"`

echo "NASID=$NASID WLAN=$WLAN WLANMAC=$WLANMAC UPTIME=$UPTIME UP=$UP"
logger -t uplink "NASID=$NASID WLAN=$WLAN WLANMAC=$WLANMAC UPTIME=$UPTIME UP=$UP"

# Perform uplink, and get result
OUT=/tmp/up.result
/usr/bin/wget http://tech.hotspotsystem.com/up.php?mac=$WLANMAC\&nasid=$NASID\&os_date=OpenWrt\&uptime=\$UP --output-document $OUT

# See file commands
echo -e "Content of: $OUT\n"
CONTENT=`cat $OUT`
echo $CONTENT
logger -t uplink "Uplink script returned: $CONTENT"

# Execute possible commands
chmod 755 /tmp/up.result
/tmp/up.result
rm -rf /tmp/up.result


