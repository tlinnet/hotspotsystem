#!/bin/bash

DEFPERFORM=y
# Install packages for openvpn
mkl2tp() {
    echo -e "\nThis will install packages for L2TP"
    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        echo -e "\nInstalling packages: xl2tpd unzip"
        opkg update && opkg install xl2tpd unzip

    else
        echo -e "\nSkipping"
    fi
}

# Get certificates for PIA Private Internet Access 
mkcert() {
    echo -e "\nThis will get certificates for PIA Private Internet Access "
    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        mkdir -p /etc/openvpn/pia
        curl -k -L https://www.privateinternetaccess.com/openvpn/openvpn.zip -o openvpn.zip
        unzip openvpn.zip -d /etc/openvpn/pia
        rm openvpn.zip
    else
        echo -e "\nSkipping"
    fi
}

# Function to create userpasswd file
mkpasswdfile() {
    echo -e "\nThis will create PPTP/L2TP/SOCKS Username and Password file for PIA Private Internet Access "

    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        PIAFILES=/etc/openvpn/pia
        PIAPASSFILE=userpass_l2tp.txt
        PIAUSERDEF=YOUR_PIA_USER
        PIAPASSDEF=YOUR_PIA_PASS

        read -p "Enter Your PPTP/L2TP/SOCKS PIA username [$PIAUSERDEF]:" PIAUSER
        PIAUSER=${PIAUSER:-$PIAUSERDEF}
        echo "You entered: $PIAUSER"

        read -p "Enter Your PPTP/L2TP/SOCKS PIA passwd [$PIAPASSDEF]:" PIAPASS
        PIAPASS=${PIAPASS:-$PIAPASSDEF}
        echo "You entered: $PIAPASS"

        # Make password file
        echo $PIAUSER > ${PIAFILES}/${PIAPASSFILE}
        echo $PIAPASS >> ${PIAFILES}/${PIAPASSFILE}
        chmod 400 ${PIAFILES}/${PIAPASSFILE}
        echo -e "\nYour PIA password file $PIAFILES/$PIAPASSFILE has the following content:"
        cat ${PIAFILES}/${PIAPASSFILE}
    else
        echo -e "\nSkipping"
    fi
}

mkinterface() {
    echo -e "\nInterface for L2TP"

    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        PIAFILES=/etc/openvpn/pia
        PIAPASSFILE=userpass_l2tp.txt
        PIASETUPDEF=Denmark.ovpn

        # Make l2tp interface
        PIANETWORK=pia_l2tp
        PIAIF=l2tp-vpn

        echo ""
        read -p "Enter file name for settings [$PIASETUPDEF]:" PIASETUP
        PIASETUP=${PIASETUP:-$PIASETUPDEF}

        echo -e "\nNow reading settings from ${PIAFILES}/${PIASETUP}"
        PIAREMOTE=`grep "remote " ${PIAFILES}/${PIASETUP} | sed "s/remote //g" | cut -d " " -f1`

        echo -e "\nNow reading user/pass settings from ${PIAFILES}/${PIAPASSFILE}"
        PIAUSER=`cat ${PIAFILES}/${PIAPASSFILE} | awk 'NR==1'`
        PIAPASS=`cat ${PIAFILES}/${PIAPASSFILE} | awk 'NR==2'`

        # Now make network
        uci show network
        uci set network.${PIANETWORK}=interface
        uci set network.${PIANETWORK}.ifname="$PIAIF"
        uci set network.${PIANETWORK}.proto='l2tp'
        uci set network.${PIANETWORK}.username="$PIAUSER"
        uci set network.${PIANETWORK}.password="$PIAPASS"
        uci set network.${PIANETWORK}.server="$PIAREMOTE"
        uci set network.${PIANETWORK}.auto='1'
        uci commit network
        uci show network

        # Add firewall zone
        PIAFWZONE=l2tp_fw

        uci show firewall | grep zone
        uci add firewall zone
        uci set firewall.@zone[-1].name="$PIAFWZONE"
        uci set firewall.@zone[-1].input='REJECT'
        uci set firewall.@zone[-1].output='ACCEPT'
        uci set firewall.@zone[-1].forward='REJECT'
        uci set firewall.@zone[-1].masq='1'
        uci set firewall.@zone[-1].mtu_fix='1'
        uci set firewall.@zone[-1].network=$PIANETWORK
        uci commit firewall
        uci show firewall | grep zone

        # Add forward from lan to zone
        uci show firewall | grep forwarding
        uci add firewall forwarding
        uci set firewall.@forwarding[-1].dest="$PIAFWZONE"
        uci set firewall.@forwarding[-1].src='lan'
        uci commit firewall
        uci show firewall | grep forwarding

        # Restart firewall and stop openvpn service
        /etc/init.d/firewall restart
    else
        echo -e "\nSkipping"
    fi
}

mkstartl2tp() {
    echo -e "\nStart L2TP?."

    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        echo -e "\nNow trying: ifup pia_l2tp"
        ifup pia_l2tp

        echo -e "\nCheck if it works with these commands"
        echo -e "logread"
        echo -e "ifconfig"
        echo -e "wget http://ipinfo.io/ip -qO -"
    else
        echo -e "\nSkipping"
    fi
}


# Perform
mkl2tp
mkcert
mkpasswdfile
mkinterface
mkstartl2tp