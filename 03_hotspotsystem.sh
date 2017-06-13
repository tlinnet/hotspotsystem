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
        /etc/init.d/chilli stop
        /etc/init.d/chilli disable
    else
        echo -e "\nSkipping"
    fi
}

mkfixdate() {
    echo -e "\nWe have to fix the date settings"

    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        date
        echo "uci set system.@system[0].timezone='UTC'"

        uci set system.@system[0].timezone='UTC'
        uci commit system
        date
    else
        echo -e "\nSkipping"
    fi
}

mkfixnetstate() {
    echo -e "\nWe have to fix a bug in /etc/hotplug.d/iface/00-netstate"

    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        echo -e "\nFixing a bug in /etc/hotplug.d/iface/00-netstate"
        cat /etc/hotplug.d/iface/00-netstate

        echo "" >> /etc/hotplug.d/iface/00-netstate
        echo '[ ifdown = "$ACTION" ] && {' >> /etc/hotplug.d/iface/00-netstate
        echo '    uci_toggle_state network "$INTERFACE" up 0' >> /etc/hotplug.d/iface/00-netstate
        echo '}' >> /etc/hotplug.d/iface/00-netstate

        echo -e "\nNow it is /etc/hotplug.d/iface/00-netstate"
        cat /etc/hotplug.d/iface/00-netstate
    else
        echo -e "\nSkipping"
    fi
}

mkchillihotplug() {
    echo -e "\nThere is a default hotplug script in /etc/hotplug.d/iface/30-chilli"
    cat /etc/hotplug.d/iface/30-chilli

    echo -e "\nWe are going to replace it with a little more intelligent script."
    echo -e "You can always unplug your connection to the wan, to reach the router."
    echo -e "This will disable the hotplug event."

    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        echo -e "\nLinking script"
        echo -e "ln -s $PWD/03_etc_hotplug_d_iface_30-chilli /etc/hotplug.d/iface/30-chilli"
        # Copy over 30-chilli script
        rm /etc/hotplug.d/iface/30-chilli
        ln -s $PWD/03_etc_hotplug_d_iface_30-chilli /etc/hotplug.d/iface/30-chilli

    else
        echo -e "\nSkipping"
    fi
}

mkchilliconf() {
    echo -e "\nThis will make a standard chilli configuration"
    echo -e "Please read: https://wiki.openwrt.org/doc/howto/wireless.hotspot.coova-chilli"
    unset PERFORM
    read -p "Should I perform this? [$DEFPERFORM]:" PERFORM
    PERFORM=${PERFORM:-$DEFPERFORM}
    echo -e "You entered: $PERFORM"
    if [ "$PERFORM" == "y" ]; then
        echo "Your current settings are:"
        uci show chilli
        # Make backup
        cp /etc/config/chilli /etc/config/chilli_default
        uci show chilli > old_uci_chilli

        # Make the config for chilli
        echo "" > /etc/config/chilli
        # The config HAS to be chilli. Or else it won't work!
        uci add chilli chilli

        DEFOPERATOR=my_hotspotsystem_com_login_name
        read -p "What is your login name to hotspotsystem.com? [$DEFOPERATOR]:" OPERATOR
        OPERATOR=${OPERATOR:-$DEFOPERATOR}
        echo -e "You entered: $OPERATOR"

        DEFLOCID=1
        read -p "What is 'Loc. ID' for the hotspot location? [$DEFLOCID]:" LOCID
        LOCID=${LOCID:-$DEFLOCID}
        echo -e "You entered: $LOCID"

        echo "uci set chilli.@chilli[0].radiusnasid=${OPERATOR}_${LOCID}"
        uci set chilli.@chilli[0].radiusnasid="${OPERATOR}_${LOCID}"

        echo -e "\nI have an 03_hotspotsystem_uplink.sh script to hotspotsystem"

        unset PERFORM
        read -p "Should I run the 03_hotspotsystem_uplink.sh script now? [$DEFPERFORM]:" PERFORM
        PERFORM=${PERFORM:-$DEFPERFORM}
        echo -e "You entered: $PERFORM"
        if [ "$PERFORM" == "y" ]; then
            ./03_hotspotsystem_uplink.sh
        else
            echo -e "\nSkipping"
        fi

        echo -e "\nMaking new crontab."
        #write out current crontab
        crontab -l > crontab_old
        touch crontab_old
        cp crontab_old crontab_new
        # At the 0-9 random minute, each hour
        RAND=`grep -m1 -ao '[0-59]' /dev/urandom | sed s/0/10/ | head -n1`
        echo "$RAND * * * * /root/hotspotsystem/03_hotspotsystem_uplink.sh" >> crontab_new
        echo -e "\nThis is the new crontab."
        cat crontab_new

        unset PERFORM
        read -p "Should I add this new crontab? [$DEFPERFORM]:" PERFORM
        PERFORM=${PERFORM:-$DEFPERFORM}
        echo -e "You entered: $PERFORM"
        if [ "$PERFORM" == "y" ]; then
            crontab crontab_new
            crontab -l
        else
            echo -e "\nSkipping"
        fi

        # Get default from hotspotsystem
        #wget -O hotspotsystem_etc_init_d_chilli http://www.hotspotsystem.com/firmware/openwrt/chilli
        wget -O hotspotsystem_etc_chilli_defaults.tmp http://hotspotsystem.com/firmware/openwrt/defaults

        DEFUAMSECRET=`cat hotspotsystem_etc_chilli_defaults.tmp | grep UAMSECRET | cut -d '"' -f2`
        read -p "What is the UAMSECRET for the hotspot location? [$DEFUAMSECRET]:" UAMSECRET
        UAMSECRET=${UAMSECRET:-$DEFUAMSECRET}
        echo -e "You entered: $UAMSECRET"
        uci set chilli.@chilli[0].uamsecret="$UAMSECRET"

        DEFRADIUSSECRET=`cat hotspotsystem_etc_chilli_defaults.tmp | grep RADSECRET | cut -d '"' -f2`
        read -p "What is the RADIUSSECRET for the hotspot location? [$DEFRADIUSSECRET]:" RADIUSSECRET
        RADIUSSECRET=${RADIUSSECRET:-$DEFRADIUSSECRET}
        echo -e "You entered: $RADIUSSECRET"
        uci set chilli.@chilli[0].radiussecret="$RADIUSSECRET"

        # Can be changed later
        uci set chilli.@chilli[0].locationname="human_readible_location_name"
        #uci set chilli.@chilli[0].radiuslocationname="<SSID>,<sub-ID>"

        #  WISPr the values are shown here. (cc=2-digit ISO country; idd=phone-country;ac=phone-area-code)
        ##uci set chilli.@chilli[0].radiuslocationid="isocc=<cc>,cc=<idd>,ac=<ac>,network=<SSID>"
        #uci set chilli.@chilli[0].radiuslocationid="isocc=se,cc=46,ac=584,network=CampingTiveden"
        uci set chilli.@chilli[0].radiuslocationid="1"

        # Radius parameters (change to the one for your provider)
        RADIUS1=`cat hotspotsystem_etc_chilli_defaults.tmp | grep RADIUS= | cut -d"=" -f2`
        echo -e "\nSetting radius server"
        echo "uci set chilli.@chilli[0].radiusserver1=$RADIUS1"
        uci set chilli.@chilli[0].radiusserver1="$RADIUS1"

        RADIUS2=`cat hotspotsystem_etc_chilli_defaults.tmp | grep RADIUS2= | cut -d"=" -f2`
        echo "uci set chilli.@chilli[0].radiusserver2=$RADIUS2"
        uci set chilli.@chilli[0].radiusserver2="$RADIUS2"

        echo -e "\nNow setting your device's interface on which to put the hotspot. This is subscriber interface for client devices"
        WLAN=`ifconfig | grep wl | sort | head -1 | cut -d " " -f1`
        echo "Your wlan has interface: $WLAN"
        echo "But you could also use bridged lan 'br-lan', to support both LAN and wireless radio"
        echo "See: https://help.hotspotsystem.com/knowledgebase/offer-hotspot-service-via-the-lan-ports-wired-connection"
        echo "NOTE: IF you are going to COMBINE openvpn AND coova-chilli, make sure that the tun interface for openvpn is started first!!."
        echo "Or else there will be problems with the capture of the traffic from coova-chilli and redirecting."

        DEFDHCPIF="br-lan"
        read -p "What is the interface DHCPIF for the hotspot location? [$DEFDHCPIF]:" DHCPIF
        DHCPIF=${DHCPIF:-$DEFDHCPIF}
        echo -e "You entered: $DHCPIF"
        echo "uci set chilli.@chilli[0].dhcpif=$DHCPIF"
        uci set chilli.@chilli[0].dhcpif="$DHCPIF"

        ## set DNS to whatever is fastest. On slow saturated lines, best use your local router for caching.
        ## on fast & wide lines, use or Google or your ISP's dns, whichever is fastest
        ## Will be suggested to the client. If omitted the system default will be used.
        ##uci set chilli.@chilli[0].dns1='8.8.8.8'
        ##uci set chilli.@chilli[0].dns2='8.8.4.4'
        ## PIA https://helpdesk.privateinternetaccess.com/hc/en-us/articles/219460397-How-to-change-DNS-settings-in-Windows
        ##uci set chilli.@chilli[0].dns1='209.222.18.222'
        ##uci set chilli.@chilli[0].dns2='209.222.18.218'
        ## https://www.lifewire.com/free-and-public-dns-servers-2626062
        ## https://freedns.zone/en/ Surf freely. No DNS redirects. No Logging.
        echo -e "\nSetting DHCP servers to client to use freedns. Surf freely. No DNS redirects. No Logging."
        echo -e "Read: https://freedns.zone/en"
        echo "uci set chilli.@chilli[0].dns1='37.235.1.174'"
        echo "uci set chilli.@chilli[0].dns2='37.235.1.177'"
        uci set chilli.@chilli[0].dns1='37.235.1.174'
        uci set chilli.@chilli[0].dns2='37.235.1.177'

        # Setting DNS domain
        uci set chilli.@chilli[0].domain='key.chillispot.info'

        ## Tunnel and Subnet
        ## Name of TUN device name. required.
        DEFTUNDEV="tun0"
        read -p "What is the TUN device name for the hotspot? [$DEFTUNDEV]:" TUNDEV
        TUNDEV=${TUNDEV:-$DEFTUNDEV}
        echo -e "You entered: $TUNDEV"
        echo "uci set chilli.@chilli[0].tundev=$TUNDEV"
        uci set chilli.@chilli[0].tundev="$TUNDEV"

        # For 1000 addresses. Default is 182/24 subnet
        uci set chilli.@chilli[0].net='192.168.180.0/22'
        ## keep it at 182.1 despite the 180/22 subnet
        uci set chilli.@chilli[0].uamlisten='192.168.182.1'
        # 1 day. 24 H
        uci set chilli.@chilli[0].lease='86400'
        ## 2 days. 48 H
        #uci set chilli.@chilli[0].lease='172800'
        ## plus 10 minutes
        uci set chilli.@chilli[0].leaseplus='600'

        ## Universal access method (UAM) parameters
        uci set chilli.@chilli[0].uamhomepage=""
        uci set chilli.@chilli[0].uamserver="https://customer.hotspotsystem.com/customer/hotspotlogin.php"

        ## HotSpot UAM Port (on subscriber network)
        uci set chilli.@chilli[0].uamport='3990'
        ## HotSpot UAM "UI" Port (on subscriber network, for embedded portal)
        uci set chilli.@chilli[0].uamuiport='4990'
        uci set chilli.@chilli[0].uamanydns='1'

        ## Is not set. Change so default: http://1.0.0.1 will goto login page
        uci set chilli.@chilli[0].uamaliasip='1.0.0.1'
        ## Set so http://login will goto login page
        uci set chilli.@chilli[0].uamaliasname='login'
        ## Is not set. Change so default: http://1.0.0.0 will logout
        ##uci set chilli.@chilli[0].uamlogoutip='1.0.0.0'
        ## no success page, to original requested URL
        #uci set chilli.@chilli[0].nouamsuccess='1'

        ## Hosts; services; network segments the client can access without first authenticating (walled garden)
        ## Hosts are evaluated every 'interval', but this does not work well on multi-homed (multi-IP'ed) hosts, use IP instead.
        ##uci set chilli.@chilli[0].uamallowed="customer.hotspotsystem.com,www.directebanking.com,betalen.rabobank.nl,ideal.ing.nl,ideal.abnamro.nl,www.ing.nl"
        A='194.149.46.0/24,198.241.128.0/17,66.211.128.0/17,216.113.128.0/17,70.42.128.0/17,128.242.125.0/24,216.52.17.0/24,62.249.232.74,155.136.68.77,155.136.66.34,66.4.128.0/17,66.211.128.0/17,66.235.128.0/17,88.221.136.146,195.228.254.149,195.228.254.152,203.211.140.157,203.211.150.204'
        B='www.paypal.com,www.paypalobjects.com,live.adyen.com,www.worldpay.com,select.worldpay.com,secure.ims.worldpay.com,www.rbsworldpay.com,secure.wp3.rbsworldpay.com,www.directebanking.com,betalen.rabobank.nl,ideal.ing.nl,ideal.abnamro.nl,www.ing.nl,api.mailgun.net,www.hotspotsystem.com,customer.hotspotsystem.com,tech.hotspotsystem.com'
        C='a1.hotspotsystem.com,a2.hotspotsystem.com,a3.hotspotsystem.com,a4.hotspotsystem.com,a5.hotspotsystem.com,a6.hotspotsystem.com,a7.hotspotsystem.com,a8.hotspotsystem.com,a9.hotspotsystem.com,a10.hotspotsystem.com,a11.hotspotsystem.com,a12.hotspotsystem.com,a13.hotspotsystem.com,a14.hotspotsystem.com,a15.hotspotsystem.com,a16.hotspotsystem.com,a17.hotspotsystem.com,a18.hotspotsystem.com,a19.hotspotsystem.com'
        D='a20.hotspotsystem.com,a21.hotspotsystem.com,a22.hotspotsystem.com,a23.hotspotsystem.com,a24.hotspotsystem.com,a25.hotspotsystem.com,a26.hotspotsystem.com,a27.hotspotsystem.com,a28.hotspotsystem.com,a29.hotspotsystem.com,a30.hotspotsystem.com'
        uci set chilli.@chilli[0].uamallowed="${A},${B},${C},${D}"

        ## Domain suffixes the client can access without first authenticating (walled garden)
        ## Host on the domain are checked by spying on DNS requests, so this does work for multi-homed hosts too.
        ##uci set chilli.@chilli[0].uamdomain=".paypal.com,.paypalobjects.com,.worldpay.com,.rbsworldpay.com,.adyen.com,.hotspotsystem.com"
        uci set chilli.@chilli[0].uamdomain="paypal.com,paypalobjects.com,worldpay.com,rbsworldpay.com,adyen.com,hotspotsystem.com,geotrust.com,triodos.nl,asnbank.nl,knab.nl,regiobank.nl,snsbank.nl"

        ## Various debug and optimization values
        ## swap input and output octets
        uci set chilli.@chilli[0].swapoctets='1'
        ## Re-read configuration file at this interval. Will also cause new domain name lookups to be performed. Value is given in seconds. Config file and host lookup refresh.
        uci set chilli.@chilli[0].interval='3600'

        ## Add the chilli firewall rules
        uci set chilli.@chilli[0].ipup='/etc/chilli/up.sh'
        uci set chilli.@chilli[0].ipdown='/etc/chilli/down.sh'

        ## Include this flag to include debug information.
        ##uci set chilli.@chilli[0].debug='9'

        ## Finish
        uci commit chilli

        ###########################
        # Make the config for chilli hotplug_hotplug
        echo "" > /etc/config/chilli_hotplug
        uci add chilli_hotplug chilli

        # Enable chilli hotplug
        uci set chilli_hotplug.@chilli[0].disabled='0'

        # Enable the wan to wait for ifup
        DEFWAN="wan1"
        read -p "What is the interface WAN for the hotspot connection? [$DEFWAN]:" WAN
        WAN=${WAN:-$DEFWAN}
        echo -e "You entered: $WAN"
        echo "uci set chilli_hotplug.@chilli[0].wan=$WAN"
        uci set chilli_hotplug.@chilli[0].wan="$WAN"

        # Make a variable for the tun interface
        uci set chilli_hotplug.@chilli[0].interface="hotspotsystem"

        # Default: Do not disable dhcp.lan.ignore
        uci set chilli_hotplug.@chilli[0].dhcp_lan_ignore="0"

        # Enable firewall rule for removal of access to wan
        uci set chilli_hotplug.@chilli[0].wan_firewall_enabled="1"

        ## Finish
        uci commit chilli_hotplug

        ###########################
        echo -e "\nNOTE: You should NOT do: /etc/init.d/chilli enable"
        echo -e "\nThere is a default hotplug script in /etc/hotplug.d/iface/30-chilli"
        cat /etc/hotplug.d/iface/30-chilli

        echo -e "\nYou can always unplug your connections to the wan, to reach the router."
        echo -e "This will disable the hotplug event."

        echo -e "\nYou can now try:"
        echo -e "ACTION=ifup"
        echo -e "INTERFACE=`uci get chilli_hotplug.@chilli[0].wan`"
        echo -e "source /etc/hotplug.d/iface/30-chilli"

        echo -e "\nCheck if it works with these commands"
        echo -e "logread"
        echo -e "ifconfig"
        echo -e 'ls /var/run/chilli_*.conf'
        echo -e 'Read more here: https://wiki.openwrt.org/doc/howto/wireless.hotspot.coova-chilli'
    else
        echo -e "\nSkipping"
    fi
}

# Perform
mkchilli
#mkfixdate
mkfixnetstate
mkchillihotplug
mkchilliconf
