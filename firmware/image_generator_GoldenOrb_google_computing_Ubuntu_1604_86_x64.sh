#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying relax on Google Cloud Computing GCC

#####################################
# From cmd of Google Cloud Instance.
#####################################

echo "See: https://ofmodemsandmen.com/build.html"

# Instal packages
sudo apt-get update
sudo apt-get -y install subversion git gawk gettext ncurses-dev zlib1g-dev libssl-dev libxslt1-dev wget
sudo apt-get -y install build-essential
sudo apt-get -y install unzip

# Get scripts for building
cd $HOME
mkdir openwrt
cd openwrt

# Get the latest stable
wget https://ofmodemsandmen.com/download/goldenorb.zip
unzip goldenorb.zip
rm goldenorb.zip

# Try make a minimal default image
cd chaoscalmer
./setup

# Afterwards
cd openwrt

# Find config files for GL.iNet 6416
grep -r "6416" | grep "^mk"
# Then find .config file position
head -n 30 mkmulti8 | grep "cp ./configfiles/.config"

# Then make config
make menuconfig
