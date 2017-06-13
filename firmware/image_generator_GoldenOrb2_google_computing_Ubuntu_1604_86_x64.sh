#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying on Google Cloud Computing GCC



##########################################################################
# Make a computer with 16 CPUs
# Make sure, that harddisk space is larger than 10 GB. Preferably 30 GB
# Select an Ubuntu 16.04 LTS
##########################################################################


#####################################
# From cmd of Google Cloud Instance.
#####################################

echo "See: https://ofmodemsandmen.com/build.html"
echo "See https://forums.whirlpool.net.au/forum-replies.cfm?t=2638357&p=9"

# Instal packages
sudo apt-get update && sudo apt-get -y install subversion git gawk gettext ncurses-dev zlib1g-dev libssl-dev libxslt1-dev wget build-essential unzip
# Get scripts for building
cd $HOME

# Get GoldenOrb2 of ROOter
wget http://ofmodemsandmen.com/download/goldenorb2.zip
unzip goldenorb2.zip && rm goldenorb2.zip

# Get own Package
git clone --depth=1 https://github.com/tlinnet/hotspotsystem.git

# Get lede
git clone https://git.lede-project.org/source.git lede
cd lede
# Get current tags
git tag -l
LATEST=`git tag -l | tail -n 1`
echo "Latest tag is $LATEST"
# Check out the latest branch
git checkout tags/${LATEST} -b latest
# See current branch
git branch

# Move packages from GoldenOrb2
mv ../rooter/* package
rmdir ../rooter

# Mv packages from hotspotsystem.git
mv ../hotspotsystem/firmware/ext-* package
rm -rf ../hotspotsystem

# Update
scripts/feeds update -a
scripts/feeds install -a

#sed -i 's/luci-theme-bootstrap/luci-theme-rooter/' feeds/luci/collections/luci/Makefile
#sed -i 's/disabled=1/disabled=0/;s/ssid=LEDE/ssid=ROOter/' package/kernel/mac80211/files/lib/wifi/mac80211.sh
# Enable wifi by default and set SSID to ROOter
sed -i \
    -e 's@option disabled 1@#option disabled 1@g' \
    -e 's@option ssid     OpenWrt@option ssid     ROOter@g' \
 ./package/kernel/mac80211/files/lib/wifi/mac80211.sh

sed -i \
    -e 's@option disabled 1@#option disabled 1@g' \
    -e 's@option ssid     OpenWrt${i#0}@option ssid     ROOter${i#0}@g' \
 ./package/kernel/broadcom-wl/files/lib/wifi/broadcom.sh

# Now build.
# See: https://lede-project.org/docs/guide-developer/use-buildsystem

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
# With keayboard "y", select "ext-rooter8"
# Now with arrows+enter select "Save", and save to .config
# To check
cat .config | grep -v -e '^[[:space:]]*$' -e '^#' | head -n 20

# Before building, we weill use tmux, so we can close the connection and return later
# https://gist.github.com/henrik/1967800
tmux new -s build

# Build, and then relax for several hours...
# We now have to build. We can build with more CPU in Make
lscpu
CPU=`nproc`
echo "Number of CPU is: ${CPU}"

# Build, and then relax for several hours...
make -j${CPU}
#make

# In mac, deetach from tmux by: Ctrl+b, then just, d

#### You can return into a screen by SSH, and then
# tmux ls #list running sessions/screens
# tmux a # attach to a running session
# tmux a -t <name> # to session with name

# When it's done the firmware will be in bin/targets/<target>/<subtarget>.
# ls -la ./bin/targets/

# Copy to home, from home terminal
# gcloud compute copy-files [INSTANCE_NAME]:[REMOTE_FILE_PATH] [LOCAL_FILE_PATH]
# gcloud compute copy-files go2fast:/home/${USER}/lede/bin/targets/ar71xx/generic/lede-ar71xx-generic-gl-ar150-squashfs-sysupgrade.bin $HOME/Desktop
# gcloud compute copy-files go2fast:/home/${USER}/lede/bin/targets/ipq806x/generic/lede-ipq806x-EA8500-squashfs-factory.bin $HOME/Desktop
# gcloud compute copy-files go2fast:/home/${USER}/lede/bin/targets/ipq806x/generic/lede-ipq806x-EA8500-squashfs-sysupgrade.tar $HOME/Desktop
