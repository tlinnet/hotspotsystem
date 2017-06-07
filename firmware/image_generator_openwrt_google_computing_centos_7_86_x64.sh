#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying relax on Google Cloud Computing GCC

#####################################
# From cmd of Google Cloud Instance.
#####################################

echo "See: https://wiki.openwrt.org/doc/howto/obtain.firmware.generate"

# Instal packages
sudo yum -y install wget curl nano bzip2 git
sudo yum -y install subversion git gawk gettext ncurses-devel zlib-devel openssl-devel libxslt wget
sudo yum -y install zlib-static
sudo yum -y group install "Development Tools"

# Get scripts for building
cd $HOME
git clone https://github.com/tlinnet/hotspotsystem.git

# Set variables
RELEASE=chaos_calmer
VERSION=15.05.1
BOARD=ar71xx
STABLE=OpenWrt-ImageBuilder-${VERSION}-${BOARD}-generic.Linux-x86_64

# Get the latest stable
wget https://downloads.openwrt.org/${RELEASE}/${VERSION}/${BOARD}/generic/${STABLE}.tar.bz2
tar -xvjf ${STABLE}.tar.bz2
rm ${STABLE}.tar.bz2

# Try make a minimal default image
cd ${STABLE}

# See default repos.
cat repositories.conf

# Run make info to obtain a list of defined profiles.
make info
make info | grep -A 5 GLINET
cat target/linux/ar71xx/generic/profiles/gl-connect.mk

# PACKAGES variable specifies a list of packages to include and/or exclude when building an image with Image Generator.
# FILES variable allows custom configuration files to be included in images built with Image Generator.
# This is especially useful if you need to change the network configuration from default before flashing.

# Make initial try image
make image PROFILE=GLINET PACKAGES="wget"
ls -la bin/ar71xx/
date

# Make image with wifi open and packages for 4G modem.
make image PROFILE=GLINET PACKAGES="luci kmod-usb-net-cdc-ether usb-modeswitch" FILES=${HOME}/hotspotsystem/firmware/01_ini/
ls -la bin/ar71xx/
date

# Make image with wifi open and packages for 4G modem. Add some tools.
make image PROFILE=GLINET PACKAGES="luci kmod-usb-net-cdc-ether usb-modeswitch bash git git-http curl wget nano" FILES=${HOME}/hotspotsystem/firmware/01_ini/
ls -la bin/ar71xx/
date

# Now try with trunk
cd $HOME
RELEASE=snapshots
VERSION=trunk
BOARD=ar71xx
TRUNK=OpenWrt-ImageBuilder-${BOARD}-generic.Linux-x86_64

# Get the latest trunk
wget https://downloads.openwrt.org/${RELEASE}/${VERSION}/${BOARD}/generic/${TRUNK}.tar.bz2
tar -xvjf ${TRUNK}.tar.bz2
rm ${TRUNK}.tar.bz2

# Make image
cd ${TRUNK}

# See default repos.
cat repositories.conf

# Run make info to obtain a list of defined profiles.
make info
make info | grep -A 5 AR150
cat target/linux/ar71xx/generic/profiles/gli.mk

# Make image with wifi open and packages for 4G modem.
make image PROFILE=GL-AR150 PACKAGES="luci kmod-usb-net-cdc-ether usb-modeswitch" FILES=${HOME}/hotspotsystem/firmware/01_ini/
ls -la bin/ar71xx/
date

# Make image with wifi open and packages for 4G modem. Add some tools.
make image PROFILE=GL-AR150 PACKAGES="luci kmod-usb-net-cdc-ether usb-modeswitch bash git git-http curl wget nano" FILES=${HOME}/hotspotsystem/firmware/01_ini/
ls -la bin/ar71xx/
date

# Copy to home, from home terminal
# gcloud compute copy-files [INSTANCE_NAME]:[REMOTE_FILE_PATH] [LOCAL_FILE_PATH]
# gcloud compute copy-files buildopenwrt:/home/${USER}/OpenWrt-ImageBuilder-15.05.1-ar71xx-generic.Linux-x86_64/bin/ar71xx/openwrt-15.05.1-ar71xx-generic-gl-inet-6416A-v1-squashfs-factory.bin $HOME/Desktop
# gcloud compute copy-files buildopenwrt:/home/${USER}/OpenWrt-ImageBuilder-15.05.1-ar71xx-generic.Linux-x86_64/bin/ar71xx/openwrt-15.05.1-ar71xx-generic-gl-inet-6416A-v1-squashfs-sysupgrade.bin $HOME/Desktop
# gcloud compute copy-files buildopenwrt:/home/${USER}/OpenWrt-ImageBuilder-ar71xx-generic.Linux-x86_64/bin/ar71xx/openwrt-ar71xx-generic-gl-ar150-squashfs-sysupgrade.bin $HOME/Desktop
