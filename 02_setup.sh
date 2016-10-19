#!/bin/bash

DEFPERFORM=y
# Install packages for 4 G usb dongle “HUAWEI E3372 LTE” and make new eth2 interface on the USB port
mk4g() {
    echo -e "\nThis will install packages for 4 G usb dongle 'HUAWEI E3372 LTE' and make new eth2 interface on the USB port"
    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        echo -e "\nInstalling packages: kmod-usb-net-cdc-ether usb-modeswitch"
        opkg update && opkg install kmod-usb-net-cdc-ether usb-modeswitch

        echo -e "\nNow making an 'wan2' interface for eth2"
        uci set network.wan2=interface
        uci set network.wan2.ifname='eth2'
        uci set network.wan2.proto='dhcp'
        uci commit network
        ifup wan2

        echo -e "\nNow adding 'wan2' to the firewall zone 'lan'"
        uci set firewall.@zone[1].network='wan wan2 wan6'
        uci commit firewall
        /etc/init.d/firewall restart
    else
        echo -e "\nSkipping"  
    fi

}

# Allow SSH on wan zone
mksshwan() {
    echo -e "\nThis will allow SSH on wan zone"
    echo "Please read: https://wiki.openwrt.org/doc/howto/secure.access"
    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        DEFPORT=22
        read -p "What port to allow on wan? [$DEFPORT]:" PORT
        PORT=${PORT:-$DEFPORT}
        echo -e "You entered: $PORT"
        echo -e "\nNow setting firewall"
        uci add firewall rule
        uci set firewall.@rule[-1].name='Allow-ssh-wan'
        uci set firewall.@rule[-1].src=wan
        uci set firewall.@rule[-1].target=ACCEPT
        uci set firewall.@rule[-1].proto=tcp
        uci set firewall.@rule[-1].dest_port=$PORT
        uci commit firewall
        /etc/init.d/firewall restart
    else
        echo -e "\nSkipping"   
    fi
}

# Sync syslog to papertrailapp.com
mkpapertrail() {
    echo -e "\nThis will Sync syslog to papertrailapp.com"
    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        DEFPAPERPORT=10000
        read -p "What is the port number to your papertrail system? [$DEFPAPERPORT]:" PAPERPORT
        PAPERPORT=${PAPERPORT:-$DEFPAPERPORT}
        echo -e "You entered: $PAPERPORT"

        DEFPAPERURL=logs1.papertrailapp.com
        read -p "What is the url to your papertrail system? [$DEFPAPERURL]:" PAPERURL
        PAPERURL=${PAPERURL:-$DEFPAPERURL}
        echo -e "You entered: $PAPERURL"

        PAPERIP=`nslookup $PAPERURL | grep -m 1 "Address 1: " | cut -d" " -f3`
        echo -e "\nWhen I do a nslookup, I translate the IP to: $PAPERIP"

        uci set system.@system[0].log_ip=$PAPERIP
        uci set system.@system[0].log_port=$PAPERPORT
        uci commit system
        echo -e "\nNow setting system"
        echo -e "uci set system.@system[0].log_port=$PAPERPORT"
        echo -e "uci set system.@system[0].log_ip=$PAPERIP"
    else
        echo -e "\nSkipping" 
    fi
}

# Perform
mk4g
mksshwan
mkpapertrail