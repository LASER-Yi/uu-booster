include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for uu-booster
LUCI_DEPENDS:=+uu-booster
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-uu-booster

define Package/luci-app-uu-booster/postinst
#!/bin/sh
	[ -n "$$IPKG_INSTROOT" ] || exit 0
endef

define Package/luci-app-uu-booster/postrm
#!/bin/sh
	[ -n "$$IPKG_INSTROOT" ] || exit 0
endef

define Package/luci-app-uu-booster/install
	$(call Package/luci/install/template,$(1),applications/uu-booster)
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
