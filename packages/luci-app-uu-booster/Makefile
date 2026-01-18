include $(TOPDIR)/rules.mk

LUCI_TITLE:=UU Game Booster
LUCI_DEPENDS:=+uu-booster
LUCI_PKGARCH:=all

include ../../feeds/luci/luci.mk

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

$(eval $(call BuildPackage,luci-app-uu-booster))
