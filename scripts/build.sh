#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SDK_VERSION="22.03.7"
SDK_IMAGE="openwrt/sdk:x86_64-generic-v${SDK_VERSION}"

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

echo "Building uu-booster package..."
docker run --rm \
	-v "$PROJECT_ROOT/packages:/packages:ro" \
	-v "$PROJECT_ROOT/output:/output" \
	-e "TOPDIR=/builder" \
	"$SDK_IMAGE" /bin/sh -c "
		cp -r /packages/uu-booster /builder/package/ && \
		make package/uu-booster/compile V=s IGNORE_ERRORS=1 && \
		cp /builder/bin/packages/*/uu-booster_*.ipk /output/ 2>/dev/null || true
	"

echo "Building luci-app-uu-booster package..."
docker run --rm \
	-v "$PROJECT_ROOT/packages:/packages:ro" \
	-v "$PROJECT_ROOT/output:/output" \
	-e "TOPDIR=/builder" \
	"$SDK_IMAGE" /bin/sh -c "
		cp -r /packages/luci-app-uu-booster /builder/package/ && \
		make package/luci-app-uu-booster/compile V=s IGNORE_ERRORS=1 && \
		cp /builder/bin/packages/*/luci-app-uu-booster_*.ipk /output/ 2>/dev/null || true
	"

echo ""
echo "========================================="
echo "Build complete!"
echo "========================================="
echo ""
echo "Built packages are in: $PROJECT_ROOT/output"
ls -lh "$PROJECT_ROOT/output"/*.ipk 2>/dev/null || echo "No packages found"
