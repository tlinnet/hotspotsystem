#Owned by tlinnet@Whirlpool
#
#Copyright GNU act.
include $(TOPDIR)/rules.mk

PKG_NAME:=ext-hotspotsystem
PKG_VERSION:=1.000
PKG_RELEASE:=1

PKG_MAINTAINER:=Created by tlinnet@whirlpool
include $(INCLUDE_DIR)/package.mk

define Package/ext-hotspotsystem
  SECTION:=utils
  CATEGORY:=ROOter
  SUBMENU:=Optional Applications
  DEPENDS:=+git +git-http +curl +wget +nano +ca-bundle +grep \
 	    +coova-chilli +kmod-tun
  TITLE:=Install packages for hotspotsystem
  PKGARCH:=all
endef

define Package/ext-hotspotsystem/description
  Helper packages to install chilli for hotspotsystem.com
endef


define Build/Compile
endef

define Package/ext-hotspotsystem/install
	$(CP) ./files/* $(1)/


endef

$(eval $(call BuildPackage,ext-hotspotsystem))
