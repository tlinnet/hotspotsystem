#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying relax on Google Cloud Computing GCC

#####################################
# From cmd of Google Cloud Instance.
#####################################

echo "See: https://ofmodemsandmen.com/build.html"
echo "See: https://lede-project.org/docs/guide-developer/quickstart-build-images"

# Instal packages
sudo apt-get update
sudo apt-get install -y subversion g++ zlib1g-dev build-essential git python zlib1g-dev
sudo apt-get install -y libncurses5-dev gawk gettext unzip file libssl-dev wget
sudo apt-get install -y git-core gawk flex quilt xsltproc libxml-parser-perl

# Get scripts for building
cd $HOME
mkdir goldenorb
cd goldenorb

# Get the patches
wget https://ofmodemsandmen.com/download/goldenorb.zip
unzip goldenorb.zip
rm goldenorb.zip

# Rename
mv chaoscalmer lede
cd lede
rm setup
git clone https://git.lede-project.org/source.git lede

# Update
cd lede
./scripts/feeds update -a
./scripts/feeds install -a
cd ..

#####################################################################################
# Change Luci theme to Material
sed -i \
    -e 's@+luci-theme-bootstrap@+luci-theme-material@g' \
 ./lede/feeds/luci/collections/luci/Makefile

# Enable wifi by default and set SSID to ROOter
sed -i \
    -e 's@option disabled 1@#option disabled 1@g' \
    -e 's@option ssid     OpenWrt@option ssid     ROOter@g' \
 ./lede/package/kernel/mac80211/files/lib/wifi/mac80211.sh

sed -i \
    -e 's@option disabled 1@#option disabled 1@g' \
    -e 's@option ssid     OpenWrt${i#0}@option ssid     ROOter${i#0}@g' \
 ./lede/package/kernel/broadcom-wl/files/lib/wifi/broadcom.sh

# create folders and copy build scripts
mkdir -p lede/images
unzip ./rooter-build/rooter.zip -d ./lede/package
unzip ./rooter-build/config.zip -d ./lede

# Copy and modify files for IPv6 removal
mkdir ./lede/configfiles/IPv6Fix

cp ./lede/feeds/luci/collections/luci/Makefile ./lede/configfiles/IPv6Fix/luciMakefile
cp ./lede/feeds/luci/collections/luci/Makefile ./lede/configfiles/IPv6Fix/luciMakefile-ipv6

sed -i \
    -e 's@ +IPV6:luci-proto-ipv6@@g' \
 ./lede/configfiles/IPv6Fix/luciMakefile-ipv6

cp ./lede/include/target.mk ./lede/configfiles/IPv6Fix/targetmk
cp ./lede/include/target.mk ./lede/configfiles/IPv6Fix/targetmk-ipv6

sed -i \
    -e 's@ip6tables @@g' \
    -e 's@odhcpd @@g' \
    -e 's@ odhcp6c@@g' \
 ./lede/configfiles/IPv6Fix/targetmk-ipv6

cp ./lede/package/network/utils/iptables/Makefile ./lede/configfiles/IPv6Fix/iptableMakefile
cp ./lede/package/network/utils/iptables/Makefile ./lede/configfiles/IPv6Fix/iptableMakefile-ipv6

sed -i \
    -e 's@ +IPV6:libip6tc@@g' \
    -e 's@ +libip6tc@@g' \
    -e "/^define Package\/libiptc\/install\$/{n;\
s#^\(\s*\)\(\$(INSTALL_DIR) \$(1)/usr/lib\)\$#\
\1\$(INSTALL_DIR) \$(1)/tmp\n\
\1\$@ echo empty>\$(1)/tmp/libip6tc.so.0\n\
\1\$@ echo '------- libip6tc.so.0 hack -------'\n\
\1\2#}" \
 ./lede/configfiles/IPv6Fix/iptableMakefile-ipv6

cp ./IPv6Fix/remove-ipv6 ./lede/remove-ipv6
cp ./IPv6Fix/restore-ipv6 ./lede/restore-ipv6
cp ./IPv6Fix/fix-config ./lede/fix-config

# Specials
cp ./lede/target/linux/ar71xx/image/Makefile ./lede/configfiles/Special/Makefile
cp ./lede/tools/firmware-utils/src/mktplinkfw.c ./lede/configfiles/Special/mktplinkfw.c
cp ./lede/target/linux/ar71xx/image/Makefile ./lede/configfiles/Special/Makefile_8
cp ./lede/tools/firmware-utils/src/mktplinkfw.c ./lede/configfiles/Special/mktplinkfw_8.c
cp ./lede/target/linux/ar71xx/image/Makefile ./lede/configfiles/Special/Makefile_16
cp ./lede/tools/firmware-utils/src/mktplinkfw.c ./lede/configfiles/Special/mktplinkfw_16.c
#####################################################################################
cd lede

# Find config files for GL.iNet 6416
grep -r "6416" | grep "^mk"
# Then find .config file position
head -n 30 mkmulti8 | grep "cp ./configfiles/.config"

make defconfig
make menuconfig
#make dirclean
