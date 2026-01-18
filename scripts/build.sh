#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SDK_VERSION="22.03.7"
SDK_IMAGE="openwrt/sdk:x86-64-${SDK_VERSION}"

usage() {
	echo "Usage: $0 [architecture]"
	echo ""
	echo "Note: Packages are architecture-independent (all), building for x86_64 SDK only"
	echo "The UU booster binary will be downloaded at install-time based on detected architecture"
	echo ""
	echo "Arguments (optional):"
	echo "  any          Build generic packages (default)"
	echo "  --help, -h   Show this help message"
	exit 1
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
	usage
fi

echo ""
echo "========================================="
echo "Building generic packages"
echo "========================================="

if ! docker image inspect "$SDK_IMAGE" &> /dev/null; then
	echo "Pulling SDK image: $SDK_IMAGE"
	docker pull "$SDK_IMAGE"
fi

mkdir -p "$PROJECT_ROOT/output"

docker run --rm \
	-v "$PROJECT_ROOT/packages:/packages:ro" \
	-v "$PROJECT_ROOT/output:/output" \
	-e "TOPDIR=/builder" \
	"$SDK_IMAGE" /bin/sh -c "
		./scripts/feeds update -a
		./scripts/feeds install -a
		make defconfig
		make package/uu-booster/compile V=s IGNORE_ERRORS=1
		make package/luci-app-uu-booster/compile V=s IGNORE_ERRORS=1
		for pkg in /builder/bin/packages/*/*.ipk; do
			cp \"\$pkg\" /output/ 2>/dev/null || true
		done
	"

echo ""
echo "========================================="
echo "Build complete!"
echo "========================================="
echo ""
echo "Built packages are in: $PROJECT_ROOT/output"
ls -lh "$PROJECT_ROOT/output"/*.ipk 2>/dev/null || echo "No packages found"
