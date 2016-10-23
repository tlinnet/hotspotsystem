#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying relax on Google Cloud Computing GCC

#####################################
# From cmd of Google Cloud Instance.
#####################################

# Change default SSH settings
F='/etc/ssh/sshd_config'

A='PermitRootLogin'
B='PermitRootLogin no'
sudo cat $F | grep "$A"
sudo cat $F | sed "/\$A/c\\$B" | grep "$A"
sudo sed -i "/\$A/c\\$B" $F
sudo cat $F | grep "$A"

A='PermitEmptyPasswords'
B='PermitEmptyPasswords no'
sudo cat $F | grep "$A"
sudo cat $F | sed "/\$A/c\\$B" | grep "$A"
sudo sed -i "/\$A/c\\$B" $F
sudo cat $F | grep "$A"

sudo cat $F | grep "PasswordAuthentication"
sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" $F
sudo cat $F | grep "PasswordAuthentication"

# Add ssh rule to firewall and restart
sudo firewall-cmd --add-service=ssh --permanent 
sudo firewall-cmd --reload 

# Restart SSH daemon and enable
sudo systemctl restart sshd
sudo systemctl enable sshd

# Add user and add to sudo group
MYUSER=demo
MYUSERPASS=demopass
sudo adduser $MYUSER
echo "${MYUSER}:${MYUSERPASS}" | sudo chpasswd
sudo gpasswd -a $MYUSER wheel
su $MYUSER
mkdir ${HOME}/.ssh
chmod 700 ${HOME}/.ssh

###########################
# From OpenWrt Router
###########################
cd $HOME/.ssh
MYUSER=demo
GCIP=100.100.100.100

opkg update && opkg install sshtunnel
/etc/init.d/sshtunnel stop
/etc/init.d/sshtunnel disable

# Create dropbear key and extract public
dropbearkey -f id_dropbear -t rsa -s 2048
dropbearkey -y -f id_dropbear > id_dropbear.pub

# Copy over public key, and then access
scp id_dropbear.pub ${MYUSER}@${GCIP}:/home/${MYUSER}/.ssh/authorized_keys

ssh -y ${MYUSER}@${GCIP}

#####################################
# From cmd of Google Cloud Instance.
#####################################
# Remove password access
F='/etc/ssh/sshd_config'

sudo cat $F | grep "PasswordAuthentication"
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" $F
sudo cat $F | grep "PasswordAuthentication"
sudo systemctl restart sshd

###########################
# From OpenWrt Router
###########################


cat /etc/config/sshtunnel
cp /etc/config/sshtunnel /etc/config/sshtunnel_orig

MYUSER=demo
GCIP=100.100.100.100
LOCAL=`uci get network.lan.ipaddr`
uci set sshtunnel.rssh=tunnelR
uci set sshtunnel.rssh.server='Google Cloud'
uci set sshtunnel.rssh.remoteaddress=${GCIP}
uci set sshtunnel.rssh.remoteport='22'
uci set sshtunnel.rssh.user=${MYUSER}
uci set sshtunnel.rssh.localaddress=$LOCAL
uci set sshtunnel.rssh.localport='50022'

uci commit sshtunnel
uci show sshtunnel
/etc/init.d/sshtunnel start
logread

#####################################
# From cmd of Google Cloud Instance.
#####################################
journalctl -u sshd |tail -100

MYUSER=demo
GCIP=100.100.100.100
ssh -y -p 22 ${MYUSER}@localhost


