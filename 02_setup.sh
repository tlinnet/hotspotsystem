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

        # Inspect
        #cat /sys/kernel/debug/usb/devices
        #grep -B 3 -A 20 "HUAWEI" /sys/kernel/debug/usb/devices

        #T:  Bus=01 Lev=01 Prnt=01 Port=00 Cnt=01 Dev#=  3 Spd=480  MxCh= 0
        #D:  Ver= 2.10 Cls=02(comm.) Sub=00 Prot=00 MxPS=64 #Cfgs=  1
        #P:  Vendor=12d1 ProdID=14dc Rev= 1.02
        #S:  Manufacturer=HUAWEI_MOBILE
        #S:  Product=HUAWEI_MOBILE
        #C:* #Ifs= 3 Cfg#= 1 Atr=80 MxPwr=  2mA
        #I:* If#= 0 Alt= 0 #EPs= 1 Cls=02(comm.) Sub=06 Prot=00 Driver=cdc_ether
        #E:  Ad=83(I) Atr=03(Int.) MxPS=  16 Ivl=2ms
        #I:* If#= 1 Alt= 0 #EPs= 2 Cls=0a(data ) Sub=06 Prot=00 Driver=cdc_ether
        #E:  Ad=82(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
        #E:  Ad=02(O) Atr=02(Bulk) MxPS= 512 Ivl=0ms
        #I:* If#= 2 Alt= 0 #EPs= 2 Cls=08(stor.) Sub=06 Prot=50 Driver=(none)
        #E:  Ad=84(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
        #E:  Ad=03(O) Atr=02(Bulk) MxPS= 512 Ivl=125us

        #dmesg | grep cdc_ether
        #[   14.450000] usbcore: registered new interface driver cdc_ether
        #[   25.630000] cdc_ether 1-1:1.0 eth2: register 'cdc_ether' at usb-ehci-platform-1, CDC Ethernet Device, 0c:5b:8f:27:9a:64
        #[   28.360000] cdc_ether 1-1:1.0 eth2: kevent 12 may have been dropped

        #lsmod | grep usb

        # Try other driver:  https://forum.openwrt.org/viewtopic.php?id=55691
        #opkg update && opkg install kmod-usb-net-huawei-cdc-ncm
        # Does not work

        # Try https://wiki.openwrt.org/doc/recipes/ethernetoverusb_rndis
        #opkg update && opkg install kmod-usb-net-rndis usb-modeswitch
        # Does not work

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

        PAPERIP=`nslookup $PAPERURL | grep -m 1 "Address" | cut -d":" -f2 | sed 's/#.*//' | cut -d" " -f2 | tr -d " \t"`
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

# Many syslog messages of the format "DHCPV6 SOLICIT IA_NA from ..."
dhcpv6disabled() {
    echo -e "\nThis will remove syslog messages of the format 'DHCPV6 SOLICIT IA_NA from ...'"
    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        # https://wiki.openwrt.org/doc/techref/odhcpd#many_syslog_messages_of_the_format_dhcpv6_solicit_ia_na_from
        # get the current setting for dhcpv6 in /etc/config/dhcp
        uci get dhcp.lan.dhcpv6
        uci set dhcp.lan.dhcpv6=disabled
        uci commit
        uci get dhcp.lan.dhcpv6
        /etc/init.d/odhcpd restart
        echo -e "\nNow setting system"
        echo -e "uci set dhcp.lan.dhcpv6=disabled"
        echo -e "uci commit"
        echo -e "/etc/init.d/odhcpd restart"
    else
        echo -e "\nSkipping"
    fi
}

# Perform
mk4g
mksshwan
mkpapertrail
dhcpv6disabled
