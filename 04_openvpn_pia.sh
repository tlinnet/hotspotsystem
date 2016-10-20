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
    echo -e "\nThis will create userpasswd file PIA Private Internet Access "

    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        PIAFILES=/etc/openvpn/pia
        PIAPASSFILE=userpass.txt
        PIAUSERDEF=YOUR_PIA_USER
        PIAPASSDEF=YOUR_PIA_PASS

        read -p "Enter Your PIA user [$PIAUSERDEF]:" PIAUSER
        PIAUSER=${PIAUSER:-$PIAUSERDEF}
        echo "You entered: $PIAUSER"

        read -p "Enter Your PIA passwd [$PIAPASSDEF]:" PIAPASS
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

mkdhcpfile() {
    echo -e "\nMake a DHCP option file. When connected to the VPN, your ISP DNS server will no longer work."
    echo "This is because your IP address no longer belong to their own pool of accepted clients to their DNS servers."

    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        PIAFILES=/etc/openvpn/pia

        echo "" > $PIAFILES/up.sh
        chmod +x $PIAFILES/up.sh
        echo '#!/bin/ash' >> $PIAFILES/up.sh
        echo '#uci add_list dhcp.@dnsmasq[-1].server=209.222.18.222' >> $PIAFILES/up.sh
        echo '#uci add_list dhcp.@dnsmasq[-1].server=209.222.18.218' >> $PIAFILES/up.sh
        echo 'uci add_list dhcp.@dnsmasq[-1].server=37.235.1.174' >> $PIAFILES/up.sh
        echo 'uci add_list dhcp.@dnsmasq[-1].server=37.235.1.177' >> $PIAFILES/up.sh
        echo 'uci commit dhcp' >> $PIAFILES/up.sh
        echo '/etc/init.d/dnsmasq restart' >> $PIAFILES/up.sh

        echo -e "\ncat of $PIAFILES/up.sh"
        cat $PIAFILES/up.sh

        echo "" >  $PIAFILES/down.sh
        chmod +x $PIAFILES/down.sh
        echo '#!/bin/ash' >> $PIAFILES/down.sh
        echo '#uci del_list dhcp.@dnsmasq[-1].server=209.222.18.222' >> $PIAFILES/down.sh
        echo '#uci del_list dhcp.@dnsmasq[-1].server=209.222.18.218' >> $PIAFILES/down.sh
        echo 'uci del_list dhcp.@dnsmasq[-1].server=37.235.1.174' >> $PIAFILES/down.sh
        echo 'uci del_list dhcp.@dnsmasq[-1].server=37.235.1.177' >> $PIAFILES/down.sh
        echo 'uci commit dhcp' >> $PIAFILES/down.sh
        echo '/etc/init.d/dnsmasq restart' >> $PIAFILES/down.sh

        echo -e "\ncat of $PIAFILES/down.sh"
        cat $PIAFILES/down.sh
    else
        echo -e "\nSkipping"
    fi
}

mksettings() {
    echo -e "\nMake settings for openvpn and PIA setup."

    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        PIALOC=pia_vpn_setup
        PIAFILES=/etc/openvpn/pia
        PIAPASSFILE=userpass.txt
        PIASETUPDEF=Denmark.ovpn

        echo ""
        read -p "Enter file name for settings [$PIASETUPDEF]:" PIASETUP
        PIASETUP=${PIASETUP:-$PIASETUPDEF}

        echo -e "\nNow reading settings from ${PIAFILES}/${PIASETUP}"
        PIAREMOTE=`grep "remote " ${PIAFILES}/${PIASETUP} | sed "s/remote //g"`

        uci set openvpn.${PIALOC}=openvpn
        uci set openvpn.${PIALOC}.enabled='1'
        uci set openvpn.${PIALOC}.remote="${PIAREMOTE}"
        uci set openvpn.${PIALOC}.up=${PIAFILES}/up.sh
        uci set openvpn.${PIALOC}.down=${PIAFILES}/down.sh
        uci set openvpn.${PIALOC}.script_security='2'

        # Set to 1
        while read p; do
            if [ `echo "$p" | wc -w` -eq 1 ]; then
                pc=`echo $p | sed "s/-/_/g"`
                if [ "$pc" == "comp_lzo" ]; then
                    uci set openvpn.${PIALOC}.${pc}='yes'
                elif [ "$pc" == "disable_occ" ]; then
                    :
                elif [ "$pc" == "auth_user_pass" ]; then
                    uci set openvpn.${PIALOC}.${pc}="$PIAFILES/$PIAPASSFILE"
                else
                    uci set openvpn.${PIALOC}.${pc}='1'
                fi
            fi
        done <${PIAFILES}/${PIASETUP}

        # Set 2 settings
        while read p; do
            if [ `echo "$p" | wc -w` -eq 2 ]; then
                IFS=' ' read -r -a pa <<< "$p"
                pcf=`echo ${pa[0]} | sed "s/-/_/g"`
                pcs=`echo ${pa[1]} | sed "s/-/_/g"`

                if [[  ${pa[0]} =~ ^(crl-verify|ca)$ ]]; then
                    uci set openvpn.${PIALOC}.${pcf}=${PIAFILES}/${pcs}
                else
                    uci set openvpn.${PIALOC}.${pcf}=${pcs}
                fi
            fi
        done <${PIAFILES}/${PIASETUP}

        # Commit changes
        uci commit openvpn

        echo -e "\nThe cipher 'aes_128_cbc' is not allowed at all. It should be 'aes-128-cbc"
        sed -i 's/aes_128_cbc/aes-128-cbc/g' /etc/config/openvpn

        uci show openvpn | grep $PIALOC

        echo -e "\nNow trying: /etc/init.d/openvpn start"
        /etc/init.d/openvpn start

        echo -e "\nCheck if it works with these commands"
        echo -e "logread"
        echo -e "ifconfig"
    else
        echo -e "\nSkipping"
    fi
}


# Perform
mkopenvpn
mkcert
mkpasswdfile
mkdhcpfile
mksettings