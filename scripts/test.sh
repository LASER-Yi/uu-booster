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

if [ ! -d "$PROJECT_ROOT/bin/packages" ]; then
	echo "Error: No packages found in bin/packages/ directory"
	echo "Please build packages first using GitHub Actions or OpenWRT SDK"
	exit 1
fi

UU_PACKAGE=$(find "$PROJECT_ROOT/bin/packages" -name "uu-booster_*_all.ipk" 2>/dev/null | head -1)

if [ -z "$UU_PACKAGE" ]; then
	echo "Error: uu-booster package not found"
	exit 1
fi

echo "Found package:"
echo "  - $(basename "$UU_PACKAGE")"
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
if [ -f /usr/sbin/uu/uu.conf ]; then
	echo "Config file exists:"
	cat /usr/sbin/uu/uu.conf
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
echo "========================================="
echo "Installation test PASSED!"
echo "========================================="
EOF

docker run --rm --platform "$PLATFORM" \
	-v "$PROJECT_ROOT/bin/packages":/packages:ro \
	-v /tmp/test-install.sh:/test-install.sh:ro \
	openwrt/rootfs:"$ROOTFS_TAG" \
	sh /test-install.sh

echo ""
echo "========================================="
echo "All tests completed successfully!"
echo "========================================="
