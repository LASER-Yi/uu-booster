#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SDK_VERSION="22.03.7"

ARCHES=("aarch64" "arm" "mipsel" "x86_64")

SUBTARGETS=(
	"aarch64:generic"
	"arm:cortex-a7"
	"mipsel:24kc"
	"x86_64:generic"
)

usage() {
	echo "Usage: $0 [architecture]"
	echo ""
	echo "Architectures:"
	echo "  aarch64      Build for aarch64/generic"
	echo "  arm          Build for arm/cortex-a7"
	echo "  mipsel       Build for mipsel/24kc"
	echo "  x86_64       Build for x86_64/generic"
	echo "  all          Build for all architectures"
	echo ""
	echo "Examples:"
	echo "  $0 x86_64"
	echo "  $0 all"
	exit 1
}

if [ $# -eq 0 ]; then
	usage
fi

ARCH="$1"

if [ "$ARCH" != "all" ]; then
	if [[ ! " ${ARCHES[@]} " =~ " ${ARCH} " ]]; then
		echo "Error: Unsupported architecture '$ARCH'"
		usage
	fi
fi

get_subtarget() {
	local arch="$1"
	for subtarget in "${SUBTARGETS[@]}"; do
		if [[ "$subtarget" == "${arch}:"* ]]; then
			echo "${subtarget#${arch}:}"
			return
		fi
	done
	echo "generic"
}

build_for_arch() {
	local arch="$1"
	local subtarget="$(get_subtarget "$arch")"
	local sdk_image="openwrt/sdk:${arch}-${subtarget}-v${SDK_VERSION}"
	
	echo ""
	echo "========================================="
	echo "Building for $arch ($subtarget)"
	echo "========================================="
	
	if ! docker image inspect "$sdk_image" &> /dev/null; then
		echo "Pulling SDK image: $sdk_image"
		docker pull "$sdk_image"
	fi
	
	mkdir -p "$PROJECT_ROOT/output"
	
	echo "Building uu-booster package..."
	docker run --rm \
		-v "$PROJECT_ROOT/packages:/packages:ro" \
		-v "$PROJECT_ROOT/output:/output" \
		-e "TOPDIR=/builder" \
		"$sdk_image" /bin/sh -c "
			cp -r /packages/uu-booster /builder/package/ && \
			make package/uu-booster/compile V=s IGNORE_ERRORS=1 && \
			cp /builder/bin/packages/*/uu-booster_*.ipk /output/ 2>/dev/null || true
		"
	
	echo "Building luci-app-uu-booster package..."
	docker run --rm \
		-v "$PROJECT_ROOT/packages:/packages:ro" \
		-v "$PROJECT_ROOT/output:/output" \
		-e "TOPDIR=/builder" \
		"$sdk_image" /bin/sh -c "
			cp -r /packages/luci-app-uu-booster /builder/package/ && \
			make package/luci-app-uu-booster/compile V=s IGNORE_ERRORS=1 && \
			cp /builder/bin/packages/*/luci-app-uu-booster_*.ipk /output/ 2>/dev/null || true
		"
	
	echo ""
	echo "Build complete for $arch"
}

if [ "$ARCH" == "all" ]; then
	for arch in "${ARCHES[@]}"; do
		build_for_arch "$arch"
	done
else
	build_for_arch "$ARCH"
fi

echo ""
echo "========================================="
echo "All builds complete!"
echo "========================================="
echo ""
echo "Built packages are in: $PROJECT_ROOT/output"
ls -lh "$PROJECT_ROOT/output"/*.ipk 2>/dev/null || echo "No packages found"
