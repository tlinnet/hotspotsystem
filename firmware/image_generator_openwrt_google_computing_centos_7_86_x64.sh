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

# Get the trunk
git clone git://github.com/openwrt/openwrt.git

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