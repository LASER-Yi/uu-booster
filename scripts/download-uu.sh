#!/bin/bash
set -e

API_BASE="http://router.uu.163.com/api/plugin"
ARCH="$1"

if [ -z "$ARCH" ]; then
	echo "Usage: $0 <architecture>"
	echo ""
	echo "Architectures:"
	echo "  openwrt-aarch64"
	echo "  openwrt-arm"
	echo "  openwrt-mipsel"
	echo "  openwrt-x86_64"
	echo ""
	echo "Example:"
	echo "  $0 openwrt-x86_64"
	exit 1
fi

echo "Querying UU API for: $ARCH"
echo ""

RESPONSE=$(curl -s "$API_BASE?type=$ARCH")

if [ -z "$RESPONSE" ]; then
	echo "Error: No response from API"
	exit 1
fi

echo "API Response:"
echo "$RESPONSE"
echo ""

DOWNLOAD_URL=$(echo "$RESPONSE" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')

if [ -z "$DOWNLOAD_URL" ]; then
	echo "Error: Could not extract download URL from response"
	exit 1
fi

echo "Extracted Download URL:"
echo "$DOWNLOAD_URL"
echo ""

echo "Downloading to /tmp/uu-booster.tar.gz..."
wget -O /tmp/uu-booster.tar.gz "$DOWNLOAD_URL"

if [ $? -eq 0 ]; then
	echo ""
	echo "Download successful!"
	echo "File: /tmp/uu-booster.tar.gz"
	echo "Size: $(ls -lh /tmp/uu-booster.tar.gz | awk '{print $5}')"
	
	echo ""
	echo "To extract:"
	echo "  mkdir -p /tmp/uu-booster"
	echo "  tar -xzf /tmp/uu-booster.tar.gz -C /tmp/uu-booster"
else
	echo ""
	echo "Download failed!"
	exit 1
fi
