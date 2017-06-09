#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying on Google Cloud Computing GCC

#####################################
# From cmd of Google Cloud Instance.
#####################################

echo "See: https://ofmodemsandmen.com/build.html"
echo "See https://forums.whirlpool.net.au/forum-replies.cfm?t=2638357&p=9"

# Instal packages
sudo apt-get update && sudo apt-get -y install subversion git gawk gettext ncurses-dev zlib1g-dev libssl-dev libxslt1-dev wget build-essential unzip
# Get scripts for building
cd $HOME

git clone -b v17.01.0 https://git.lede-project.org/source.git
wget http://ofmodemsandmen.com/download/goldenorb2.zip
unzip goldenorb2.zip && rm goldenorb2.zip

mv rooter/* source/package
cd source

scripts/feeds update -a
scripts/feeds install -a

#sed -i 's/luci-theme-bootstrap/luci-theme-rooter/' feeds/luci/collections/luci/Makefile
sed -i 's/disabled=1/disabled=0/;s/ssid=LEDE/ssid=ROOter/' package/kernel/mac80211/files/lib/wifi/mac80211.sh

make defconfig
make menuconfig
#make dirclean

# Example, build for Linksys EA8500
# https://lede-project.org/toh/hwdata/linksys/linksys_ea8500

# Select:
# Target System : Qualcomm Atheros IPQ806x
# Target Profile :  Linksys EA8500
# Now, we have to select the ROOter packages which, which have combined all
# the needed stuff.
#
# Go down to:
# ROOTer ->
# With keayboard "y", select "ext-rooter16", this will automatically select "ext-rooter8"
# Now with arrows+enter select "Save", and save to .config
# To check
cat .config | grep -v -e '^[[:space:]]*$' -e '^#' | head -n 20

# Before building, we weill use screen, so we can close the connection and return later
# http://aperiodic.net/screen/quick_reference
screen -S build

# We now have to build. We can build with more CPU in Make
lscpu
CPU=`nproc`
echo "Number of CPU is: ${CPU}"

# Build, and then relax for several hours...
make -j${CPU}

# You can return into a screen by SSH, and then
screen -ls #list running sessions/screens
screen -x # attach to a running session
screen -r <name> # … to session with name

# When it's done the firmware will be in bin/targets/<target>/<subtarget>.
