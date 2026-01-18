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
	$(INSTALL_BIN) ./files/uu-update $(1)/usr/bin/uu-update
 endef

define Package/uu-booster/postinst
#!/bin/sh
	[ -n "$$IPKG_INSTROOT" ] || exit 0
	
	echo "Downloading UU Booster binary..."
	
	ARCH=$$(grep '^DISTRIB_ARCH' /etc/openwrt_release | awk -F "'" '{print $$2}')
	
	case "$$ARCH" in
		aarch64_*)
			UU_ARCH="aarch64"
			;;
		arm_*)
			UU_ARCH="arm"
			;;
		mips_*)
			UU_ARCH="mipsel"
			;;
		x86_64)
			UU_ARCH="x86_64"
			;;
		*)
			echo "Unsupported architecture: $$ARCH"
			exit 1
			;;
	esac
	
	cd /tmp
	rm -rf uu-booster
	mkdir -p uu-booster
	cd uu-booster
	
	echo "Querying UU API for $$UU_ARCH..."
	API_RESPONSE=$$(curl -s "http://router.uu.163.com/api/plugin?type=openwrt-$$UU_ARCH")
	
	if [ -z "$$API_RESPONSE" ]; then
		echo "Error: No response from UU API"
		exit 1
	fi
	
	EXPECTED_MD5=$$(echo "$$API_RESPONSE" | sed -n 's/.*"md5":"\([^"]*\)".*/\1/p')
	DOWNLOAD_URL=$$(echo "$$API_RESPONSE" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
	DOWNLOAD_URL_BAK=$$(echo "$$API_RESPONSE" | sed -n 's/.*"url_bak":"\([^"]*\)".*/\1/p')
	
	if [ -z "$$DOWNLOAD_URL" ]; then
		echo "Error: Failed to extract download URL from API response"
		exit 1
	fi
	
	if [ -z "$$EXPECTED_MD5" ]; then
		echo "Error: Failed to extract MD5 from API response"
		exit 1
	fi
	
	download_with_validation() {
		local url="$$1"
		local expected_md5="$$2"
		local attempt_num="$$3"
		
		echo "Download attempt $$attempt_num: $$url"
		wget -q -O uu-booster.tar.gz "$$url"
		
		if [ $$? -ne 0 ]; then
			echo "Error: Download failed (exit code: $$?)"
			return 1
		fi
		
		if [ ! -f uu-booster.tar.gz ]; then
			echo "Error: Downloaded file not found"
			return 1
		fi
		
		FILE_SIZE=$$(stat -c%s uu-booster.tar.gz 2>/dev/null)
		if [ -z "$$FILE_SIZE" ] || [ "$$FILE_SIZE" -lt 1024 ]; then
			echo "Error: Downloaded file too small ($$FILE_SIZE bytes), possibly an error page"
			return 1
		fi
		
		CALCULATED_MD5=$$(md5sum uu-booster.tar.gz | awk '{print $$1}')
		
		if [ -z "$$CALCULATED_MD5" ]; then
			echo "Error: Failed to calculate MD5 checksum"
			return 1
		fi
		
		echo "MD5 Check:"
		echo "  Expected: $$expected_md5"
		echo "  Calculated: $$CALCULATED_MD5"
		
		if [ "$$CALCULATED_MD5" = "$$expected_md5" ]; then
			echo "MD5 checksum: OK"
			return 0
		else
			echo "MD5 checksum: MISMATCH!"
			return 1
		fi
	}
	
	ATTEMPT=1
	
	if download_with_validation "$$DOWNLOAD_URL" "$$EXPECTED_MD5" "$$ATTEMPT"; then
		echo "Download successful and validated!"
	else
		if [ -n "$$DOWNLOAD_URL_BAK" ] && [ "$$DOWNLOAD_URL_BAK" != "$$DOWNLOAD_URL" ]; then
			ATTEMPT=2
			echo ""
			echo "Primary download failed or checksum mismatch"
			echo "Trying backup URL..."
			
			if download_with_validation "$$DOWNLOAD_URL_BAK" "$$EXPECTED_MD5" "$$ATTEMPT"; then
				echo "Download successful from backup URL and validated!"
			else
				echo ""
				echo "Error: Failed to download from both primary and backup URLs"
				echo "Please check your internet connection and try again later"
				exit 1
			fi
		else
			echo ""
			echo "Error: Primary download failed and no backup URL available"
			echo "Please check your internet connection and try again later"
			exit 1
		fi
	fi
	
	tar -xzf uu-booster.tar.gz
	
	if [ ! -f uu.conf ]; then
		echo "Error: uu.conf not found in downloaded archive"
		exit 1
	fi
	
	if [ ! -f uuplugin ]; then
		echo "Error: uuplugin not found in downloaded archive"
		exit 1
	fi
	
	mkdir -p /usr/sbin/uu
	
	cp uu.conf /etc/uu-booster.conf
	echo "Copied uu.conf to /etc/uu-booster.conf"
	
	cp uuplugin /usr/sbin/uu/
	echo "Copied uuplugin to /usr/sbin/uu/"
	
	chmod +x /usr/sbin/uu/uuplugin
	
	cd /tmp
	rm -rf uu-booster
	
	/etc/init.d/uu-booster enable
	/etc/init.d/uu-booster restart
	
	echo ""
	echo "========================================="
	echo "UU Booster installed successfully!"
	echo "========================================="
endef

define Package/uu-booster/postrm
#!/bin/sh
	/etc/init.d/uu-booster stop || true
	rm -rf /usr/sbin/uu
	rm -f /etc/uu-booster.conf
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
