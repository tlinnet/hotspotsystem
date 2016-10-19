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

        # Add new chilli
        uci add chilli hotspotsystem
        # disabled='0' to disable to running chilli. Se this option to '1' before running.
        uci set chilli.@hotspotsystem[0].disabled='0'

        DEFOPERATOR=my_hotspotsystem_com_login_name
        read -p "What is your login name to hotspotsystem.com? [$DEFOPERATOR]:" OPERATOR
        OPERATOR=${OPERATOR:-$DEFOPERATOR}
        echo -e "You entered: $OPERATOR"

        DEFLOCID=1
        read -p "What is 'Loc. ID' for the hotspot location? [$DEFLOCID]:" LOCID
        LOCID=${LOCID:-$DEFLOCID}
        echo -e "You entered: $LOCID"

        echo "uci set chilli.@hotspotsystem[0].radiusnasid=${OPERATOR}_${LOCID}"
        uci set chilli.@hotspotsystem[0].radiusnasid="${OPERATOR}_${LOCID}"

        echo -e "\mMaking an uplink.sh script to hotspotsystem"

        # Store this for uplink script
        echo "" > uplink.sh
        chmod +x uplink.sh
        echo  "#!/bin/bash" >> uplink.sh
        echo "NASID=${OPERATOR}_${LOCID}" >> uplink.sh
        echo 'WLAN=`ifconfig | grep wl | sort | head -1 | cut -d " " -f1`' >> uplink.sh
        echo 'WLANMAC=`ifconfig \$WLAN | awk '"'"'/HWaddr/ { print $5 }'"'"' | sed '"'"'s/:/-/g'"'"'`' >> uplink.sh
        echo 'UP=`uptime|sed "s/ /\%20/g"|sed "s/:/\%3A/g"|sed "s/,/\%2C/g"`' >> uplink.sh
        echo '/usr/bin/wget http://tech.hotspotsystem.com/up.php?mac=$WLANMAC\&nasid=tlinnet_4\&os_date=OpenWrt\&uptime=\$UP --output-document /tmp/up.result' >> uplink.sh
        echo 'chmod 755 /tmp/up.result' >> uplink.sh
        echo 'echo "Content of: /tmp/up.result"' >> uplink.sh
        echo 'cat /tmp/up.result' >> uplink.sh
        echo 'echo ""' >> uplink.sh
        echo '/tmp/up.result'  >> uplink.sh
        echo 'echo ""' >> uplink.sh
        echo 'echo "Printing base information"' >> uplink.sh
        echo 'echo NASID=$NASID' >> uplink.sh
        echo 'echo WLAN=$WLAN WLANMAC=$WLANMAC' >> uplink.sh
        echo 'echo UP=$UP' >> uplink.sh

        echo -e "\mMaking new crontab."
        #write out current crontab
        crontab -l > old_crontab
        touch old_crontab
        cp old_crontab new_crontab
        # At the 00'th and 30'th minute, each hour
        echo "00,30 * * * * /root/hotspotsystem/uplink.sh" >> new_crontab
        crontab new_crontab
        crontab -l

        # Get default from hotspotsystem
        wget -O etc_init_d_chilli http://www.hotspotsystem.com/firmware/openwrt/chilli
        wget -O etc_chilli_defaults.tmp http://hotspotsystem.com/firmware/openwrt/defaults

        DEFUAMSECRET=`cat etc_chilli_defaults.tmp | grep UAMSECRET | cut -d '"' -f2`
        read -p "What is the UAMSECRET for the hotspot location? [$DEFUAMSECRET]:" UAMSECRET
        UAMSECRET=${UAMSECRET:-$DEFUAMSECRET}
        echo -e "You entered: $UAMSECRET"
        uci set chilli.@hotspotsystem[0].uamsecret="$UAMSECRET"

        DEFRADIUSSECRET=`cat etc_chilli_defaults.tmp | grep RADSECRET | cut -d '"' -f2`
        read -p "What is the RADIUSSECRET for the hotspot location? [$DEFRADIUSSECRET]:" RADIUSSECRET
        RADIUSSECRET=${RADIUSSECRET:-$DEFRADIUSSECRET}
        echo -e "You entered: $RADIUSSECRET"
        uci set chilli.@hotspotsystem[0].radiussecret="$RADIUSSECRET"

        # Can be changed later
        uci set chilli.@hotspotsystem[0].locationname="human_readible_location_name"
        #uci set chilli.@hotspotsystem[0].radiuslocationname="<SSID>,<sub-ID>"

        #  WISPr the values are shown here. (cc=2-digit ISO country; idd=phone-country;ac=phone-area-code)
        ##uci set chilli.@hotspotsystem[0].radiuslocationid="isocc=<cc>,cc=<idd>,ac=<ac>,network=<SSID>"
        #uci set chilli.@hotspotsystem[0].radiuslocationid="isocc=se,cc=46,ac=584,network=CampingTiveden"
        uci set chilli.@hotspotsystem[0].radiuslocationid="1"

        # Radius parameters (change to the one for your provider)
        RADIUS1=`cat etc_chilli_defaults.tmp | grep RADIUS= | cut -d"=" -f2`
        echo -e "\nSetting radius server"
        echo "uci set chilli.@hotspotsystem[0].radiusserver1=$RADIUS1"
        uci set chilli.@hotspotsystem[0].radiusserver1="$RADIUS1"

        RADIUS2=`cat etc_chilli_defaults.tmp | grep RADIUS2= | cut -d"=" -f2`
        echo "uci set chilli.@hotspotsystem[0].radiusserver2=$RADIUS2"
        uci set chilli.@hotspotsystem[0].radiusserver2="$RADIUS2"

        echo -e "\nNow setting your device's interface on which to put the hotspot. This is subscriber interface for client devices"
        WLAN=`ifconfig | grep wl | sort | head -1 | cut -d " " -f1`
        echo "Your wlan has interface: $WLAN"
        echo "But you could also use bridged lan 'br-lan', to support both LAN and wireless radio"

        DEFDHCPIF='br-lan'
        read -p "What is the interface DHCPIF for the hotspot location? [$DEFDHCPIF]:" DHCPIF
        DHCPIF=${DHCPIF:-$DEFDHCPIF}
        echo -e "You entered: $DHCPIF"
        echo "uci set chilli.@hotspotsystem[0].dhcpif=$DHCPIF"
        uci set chilli.@hotspotsystem[0].dhcpif="$DHCPIF"

        ## set DNS to whatever is fastest. On slow saturated lines, best use your local router for caching.
        ## on fast & wide lines, use or Google or your ISP's dns, whichever is fastest 
        ## Will be suggested to the client. If omitted the system default will be used.
        ##uci set chilli.@hotspotsystem[0].dns1='8.8.8.8'
        ##uci set chilli.@hotspotsystem[0].dns2='8.8.4.4'
        ## PIA https://helpdesk.privateinternetaccess.com/hc/en-us/articles/219460397-How-to-change-DNS-settings-in-Windows
        ##uci set chilli.@hotspotsystem[0].dns1='209.222.18.222'
        ##uci set chilli.@hotspotsystem[0].dns2='209.222.18.218'
        ## https://www.lifewire.com/free-and-public-dns-servers-2626062
        ## https://freedns.zone/en/ Surf freely. No DNS redirects. No Logging.
        echo -e "\nSetting DHCP servers to client to use freedns. Surf freely. No DNS redirects. No Logging."
        echo -e "Read: https://freedns.zone/en"
        echo "uci set chilli.@hotspotsystem[0].dns1='37.235.1.174'"
        echo "uci set chilli.@hotspotsystem[0].dns2='37.235.1.177'"
        uci set chilli.@hotspotsystem[0].dns1='37.235.1.174'
        uci set chilli.@hotspotsystem[0].dns2='37.235.1.177'

        # Setting DNS domain
        uci set chilli.@hotspotsystem[0].domain='key.chillispot.info'

        ## Tunnel and Subnet 
        ## Name of TUN device name. required.
        uci set chilli.@hotspotsystem[0].tundev='tun0'
        # For 1000 addresses. Default is 182/24 subnet
        uci set chilli.@hotspotsystem[0].net='192.168.180.0/22'
        ## keep it at 182.1 despite the 180/22 subnet
        uci set chilli.@hotspotsystem[0].uamlisten='192.168.182.1'
        # 1 day. 24 H
        uci set chilli.@hotspotsystem[0].lease='86400'
        ## 2 days. 48 H
        #uci set chilli.@hotspotsystem[0].lease='172800'
        ## plus 10 minutes
        uci set chilli.@hotspotsystem[0].leaseplus='600'

        ## Universal access method (UAM) parameters
        uci set chilli.@hotspotsystem[0].uamhomepage=""
        uci set chilli.@hotspotsystem[0].uamserver="https://customer.hotspotsystem.com/customer/hotspotlogin.php"

        ## HotSpot UAM Port (on subscriber network)
        uci set chilli.@hotspotsystem[0].uamport='3990'
        ## HotSpot UAM "UI" Port (on subscriber network, for embedded portal)
        uci set chilli.@hotspotsystem[0].uamuiport='4990'
        uci set chilli.@hotspotsystem[0].uamanydns='1'

        ## Is not set. Change so default: http://1.0.0.1 will goto login page
        #uci set chilli.@hotspotsystem[0].uamaliasip='1.0.0.1'
        ## Set so http://login will goto login page
        #uci set chilli.@hotspotsystem[0].uamaliasname='login'
        ## Is not set. Change so default: http://1.0.0.0 will logout
        ##uci set chilli.@hotspotsystem[0].uamlogoutip='1.0.0.0'
        ## no success page, to original requested URL
        #uci set chilli.@hotspotsystem[0].nouamsuccess='1'

        ## Hosts; services; network segments the client can access without first authenticating (walled garden)
        ## Hosts are evaluated every 'interval', but this does not work well on multi-homed (multi-IP'ed) hosts, use IP instead.
        ##uci set chilli.@hotspotsystem[0].uamallowed="customer.hotspotsystem.com,www.directebanking.com,betalen.rabobank.nl,ideal.ing.nl,ideal.abnamro.nl,www.ing.nl"
        uci set chilli.@hotspotsystem[0].uamallowed="194.149.46.0/24,198.241.128.0/17,66.211.128.0/17,216.113.128.0/17,70.42.128.0/17,128.242.125.0/24,216.52.17.0/24,62.249.232.74,155.136.68.77,155.136.66.34,66.4.128.0/17,66.211.128.0/17,66.235.128.0/17,88.221.136.146,195.228.254.149,195.228.254.152,203.211.140.157,203.211.150.204,www.paypal.com,www.paypalobjects.com,live.adyen.com,www.worldpay.com,select.worldpay.com,secure.ims.worldpay.com,www.rbsworldpay.com,secure.wp3.rbsworldpay.com,www.directebanking.com,betalen.rabobank.nl,ideal.ing.nl,ideal.abnamro.nl,www.ing.nl,api.mailgun.net,www.hotspotsystem.com,customer.hotspotsystem.com,tech.hotspotsystem.com,a1.hotspotsystem.com,a2.hotspotsystem.com,a3.hotspotsystem.com,a4.hotspotsystem.com,a5.hotspotsystem.com,a6.hotspotsystem.com,a7.hotspotsystem.com,a8.hotspotsystem.com,a9.hotspotsystem.com,a10.hotspotsystem.com,a11.hotspotsystem.com,a12.hotspotsystem.com,a13.hotspotsystem.com,a14.hotspotsystem.com,a15.hotspotsystem.com,a16.hotspotsystem.com,a17.hotspotsystem.com,a18.hotspotsystem.com,a19.hotspotsystem.com,a20.hotspotsystem.com,a21.hotspotsystem.com,a22.hotspotsystem.com,a23.hotspotsystem.com,a24.hotspotsystem.com,a25.hotspotsystem.com,a26.hotspotsystem.com,a27.hotspotsystem.com,a28.hotspotsystem.com,a29.hotspotsystem.com,a30.hotspotsystem.com"

        ## Domain suffixes the client can access without first authenticating (walled garden)
        ## Host on the domain are checked by spying on DNS requests, so this does work for multi-homed hosts too.
        ##uci set chilli.@hotspotsystem[0].uamdomain=".paypal.com,.paypalobjects.com,.worldpay.com,.rbsworldpay.com,.adyen.com,.hotspotsystem.com"
        uci set chilli.@hotspotsystem[0].uamdomain="paypal.com,paypalobjects.com,worldpay.com,rbsworldpay.com,adyen.com,hotspotsystem.com,geotrust.com,triodos.nl,asnbank.nl,knab.nl,regiobank.nl,snsbank.nl"

        ## Various debug and optimization values
        ## swap input and output octets
        uci set chilli.@hotspotsystem[0].swapoctets='1'		
        ## Re-read configuration file at this interval. Will also cause new domain name lookups to be performed. Value is given in seconds. Config file and host lookup refresh.     
        uci set chilli.@hotspotsystem[0].interval='3600'

        ## Add the chilli firewall rules
        uci set chilli.@hotspotsystem[0].ipup '/etc/chilli/up.sh'
        uci set chilli.@hotspotsystem[0].ipdown '/etc/chilli/down.sh'

        ## Include this flag to include debug information.
        ##uci set chilli.@hotspotsystem[0].debug='9'

        ## Finish
        uci commit chilli
        uci show chilli
    else
        echo -e "\nSkipping"  
    fi

}

# Perform
mkchilli
mkchilliconf