#!/bin/bash

DEFPERFORM=y
# Install packages for openvpn
mkopenvpn() {
    echo -e "\nThis will install packages for openvpn"
    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        echo -e "\nInstalling packages: luci-app-openvpn openvpn-openssl curl unzip bash"
        opkg update && opkg install luci-app-openvpn openvpn-openssl curl unzip bash

        echo -e "\nFor safety I will stop openvpn and disable it, until you are sure system is stable"
        echo "/etc/init.d/openvpn stop"
        echo "/etc/init.d/openvpn disable"
        /etc/init.d/openvpn stop
        /etc/init.d/openvpn disable
    else
        echo -e "\nSkipping"
    fi
}

# Perform
mkopenvpn