#!/bin/bash

DEFPERFORM=y
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
#mksshwan
mkpapertrail
dhcpv6disabled
