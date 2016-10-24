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
ssh-keygen
cp $HOME/.ssh/id_rsa.pub $HOME/.ssh/authorized_keys

###########################
# From OpenWrt Router
###########################
cd $HOME/.ssh
MYUSER=demo
GCIP=104.155.3.xxx

#
opkg update && opkg install sshtunnel
/etc/init.d/sshtunnel stop
/etc/init.d/sshtunnel disable

# Copy over key, and then access
mkdir -p ${HOME}/.ssh
chmod 700 ${HOME}/.ssh
scp ${MYUSER}@${GCIP}:/home/${MYUSER}/.ssh/id_rsa ${HOME}/.ssh/id_rsa

# Try access
ssh -v ${MYUSER}@${GCIP}

#####################################
# From cmd of Google Cloud Instance.
#####################################

# See log
journalctl -u sshd |tail -100

# Remove password access
F='/etc/ssh/sshd_config'

sudo cat $F | grep "PasswordAuthentication"
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" $F
sudo cat $F | grep "PasswordAuthentication"
sudo systemctl restart sshd

###########################
# From OpenWrt Router
###########################
MYUSER=demo
GCIP=104.155.3.xxx

# -f Requests ssh to go to background just before command execution. This is useful if ssh is going to ask for passwords or passphrases, but the user wants it in the background.  This implies -n.
# -N :Do not execute a remote command.  This is useful for just forwarding ports (protocol version 2 only).
# -R : -R [bind_address:]port:host:hostport. Specifies that the given port on the remote (server) host is to be forwarded to the given host and port on the local side.

ssh -fN -R 7000:localhost:50022 ${MYUSER}@${GCIP}
echo $HOST
ps | grep 'ssh -fN'
logread

#####################################
# From cmd of Google Cloud Instance.
#####################################
journalctl -u sshd |tail -100
ssh root@localhost -p 7000


##### THIS WORKS! . :)


