#!/bin/bash

DEFPERFORM=y
# Install packages for coova-chilli
mkchilli() {
    echo -e "\nThis will install packages for coova-chilli"
    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        echo -e "\nInstalling packages: coova-chilli kmod-tun wget"
        opkg update && opkg install coova-chilli kmod-tun wget

        echo -e "\nFor safety I will stop chilli and disable it, until you are sure system is stable"
        echo "/etc/init.d/chilli stop"
        echo "/etc/init.d/chilli disable"

    else
        echo -e "\nSkipping"  
    fi

}
mkchilli

