include $(TOPDIR)/rules.mk

PKG_NAME:=uu-booster
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/uu-booster
  SECTION:=net
  CATEGORY:=Network
  TITLE:=UU Game Booster OpenWRT Unofficial Support
  DEPENDS:=+kmod-tun
  MAINTAINER:=LASER-Yi
  URL:=https://github.com/LASER-Yi/uu-booster
  PKGARCH:=all
endef

define Package/uu-booster/description
  UU game booster OpenWRT plugin - manages and accelerates gaming traffic
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/uu-booster/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/sbin/uu
	$(INSTALL_BIN) ./files/uu-booster.init $(1)/etc/init.d/uu-booster
	$(INSTALL_BIN) ./files/uu $(1)/usr/bin/uu
 endef

define Package/uu-booster/postinst
#!/bin/sh
	[ -n "$$IPKG_INSTROOT" ] && exit 0

	echo "UU Booster package installed"
	echo ""
	echo "Please run 'uu update' to download and install the UU Booster binary"
	echo ""
	echo "After installation, enable and start the service:"
	echo "  /etc/init.d/uu-booster enable"
	echo "  /etc/init.d/uu-booster start"
endef

define Package/uu-booster/postrm
#!/bin/sh
	/etc/init.d/uu-booster stop || true
	rm -rf /usr/sbin/uu
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
