#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

usage() {
	echo "Usage: $0 <architecture>"
	echo ""
	echo "Architectures:"
	echo "  x86_64       Test with x86_64 rootfs"
	echo "  aarch64       Test with aarch64 rootfs (requires QEMU)"
	echo "  arm           Test with arm rootfs (requires QEMU)"
	echo "  mipsel        Test with mipsel rootfs (requires QEMU)"
	echo ""
	echo "Note: Packages are architecture-independent (_all.ipk)"
	echo "      This only controls which OpenWRT rootfs to test with"
	exit 1
}

if [ $# -eq 0 ]; then
	usage
fi

ARCH="$1"

case "$ARCH" in
	x86_64)
		PLATFORM="linux/amd64"
		ROOTFS_TAG="x86_64"
		;;
	aarch64)
		PLATFORM="linux/arm64"
		ROOTFS_TAG="aarch64_generic"
		;;
	arm)
		PLATFORM="linux/arm/v7"
		ROOTFS_TAG="arm_cortex-a7"
		;;
	mipsel)
		PLATFORM="linux/mips"
		ROOTFS_TAG="mipsel_24kc"
		;;
	*)
		echo "Error: Unsupported architecture '$ARCH'"
		usage
		;;
esac

echo ""
echo "========================================="
echo "Testing packages on $ARCH rootfs"
echo "========================================="

if [ ! -d "$PROJECT_ROOT/output" ]; then
	echo "Error: No packages found in output/ directory"
	echo "Please build packages first using: ./scripts/build.sh"
	exit 1
fi

UU_PACKAGE=$(ls "$PROJECT_ROOT/output"/uu-booster_*_all.ipk 2>/dev/null | head -1)
LUCI_PACKAGE=$(ls "$PROJECT_ROOT/output"/luci-app-uu-booster_*.ipk 2>/dev/null | head -1)

if [ -z "$UU_PACKAGE" ]; then
	echo "Error: uu-booster package not found"
	exit 1
fi

if [ -z "$LUCI_PACKAGE" ]; then
	echo "Error: luci-app-uu-booster package not found"
	exit 1
fi

echo "Found packages:"
echo "  - $(basename "$UU_PACKAGE")"
echo "  - $(basename "$LUCI_PACKAGE")"
echo ""

echo "Pulling OpenWRT rootfs: openwrt/rootfs:$ROOTFS_TAG"
if ! docker pull --platform "$PLATFORM" "openwrt/rootfs:$ROOTFS_TAG"; then
	echo "Error: Failed to pull Docker image"
	echo "Ensure Docker is configured for multi-platform builds"
	exit 1
fi

echo ""
echo "Installing packages..."

cat << 'EOF' > /tmp/test-install.sh
set -e

echo "Updating package lists..."
opkg update

echo ""
echo "Installing uu-booster..."
opkg install /packages/uu-booster.ipk

echo ""
echo "Installing luci-app-uu-booster..."
opkg install /packages/luci-app-uu-booster.ipk

echo ""
echo "Verifying installation..."

echo "Checking binary:"
if [ -f /usr/sbin/uu/uuplugin ]; then
	/usr/sbin/uu/uuplugin --version 2>/dev/null || echo "Binary exists"
else
	echo "ERROR: Binary not found!"
	exit 1
fi

echo ""
echo "Checking config:"
if [ -f /etc/uu-booster.conf ]; then
	echo "Config file exists:"
	cat /etc/uu-booster.conf
else
	echo "ERROR: Config file not found!"
	exit 1
fi

echo ""
echo "Checking init script:"
if [ -f /etc/init.d/uu-booster ]; then
	ls -la /etc/init.d/uu-booster
else
	echo "ERROR: Init script not found!"
	exit 1
fi

echo ""
echo "Checking LuCI files:"
if [ -d /usr/lib/lua/luci/controller ] && [ -d /usr/lib/lua/luci/model/cbi ]; then
	echo "LuCI files installed"
else
	echo "ERROR: LuCI files not found!"
	exit 1
fi

echo ""
echo "========================================="
echo "Installation test PASSED!"
echo "========================================="
EOF

docker run --rm --platform "$PLATFORM" \
	-v "$PROJECT_ROOT/output":/packages:ro \
	-v /tmp/test-install.sh:/test-install.sh:ro \
	openwrt/rootfs:"$ROOTFS_TAG" \
	sh /test-install.sh

echo ""
echo "========================================="
echo "All tests completed successfully!"
echo "========================================="
