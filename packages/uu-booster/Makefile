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
  MAINTAINER:=LASER-Yi <liangyi0007@gmail.com>
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
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/sbin/uu
	$(INSTALL_BIN) ./files/uu-booster.init $(1)/etc/init.d/uu-booster
	$(INSTALL_BIN) ./files/uu $(1)/usr/bin/uu
	$(INSTALL_BIN) ./files/90-uu-booster-firewall $(1)/etc/uci-defaults/90-uu-booster-firewall
 endef

define Package/uu-booster/postinst
#!/bin/sh
	[ -n "$$IPKG_INSTROOT" ] && exit 0

	echo "UU Booster package installed"
	echo ""
	echo "Configuring firewall rules..."
	# Firewall rules configured by uci-defaults script

	echo "Downloading and installing UU Booster binary..."
	if /usr/bin/uu update >/dev/null 2>&1; then
		echo "Binary installed successfully"
		echo ""
		echo "Enabling and starting uu-booster service..."
		/etc/init.d/uu-booster enable
		if /etc/init.d/uu-booster start; then
			echo "Service started successfully"
		else
			logger -t uu-booster "Failed to start uu-booster service"
			echo "WARNING: Failed to start uu-booster service"
		fi
		echo ""
		echo "UU Booster is now running!"
	else
		logger -t uu-booster "Failed to download UU Booster binary"
		echo "WARNING: Failed to download UU Booster binary"
		echo "Run 'uu update' manually to retry"
	fi
endef

define Package/uu-booster/postrm
#!/bin/sh
	echo "Removing UU Booster..."
	echo ""

	/etc/init.d/uu-booster stop || true
	rm -rf /usr/sbin/uu

	if uci get firewall.uu >/dev/null 2>&1; then
		echo "Removing firewall rules..."
		uci delete firewall.uu
		uci delete firewall.lan_to_uu 2>/dev/null || true
		uci delete firewall.uu_to_lan 2>/dev/null || true
		uci commit firewall
		/etc/init.d/firewall reload >/dev/null 2>&1
		echo "Firewall rules removed"
	fi

	echo "UU Booster removed successfully"
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
