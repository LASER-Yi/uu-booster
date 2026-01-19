#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "UU Booster OpenWRT Packages - Quick Start"
echo "=========================================="
echo ""

echo "Choose an option:"
echo "1) Open GitHub Actions to build packages"
echo "2) Test x86_64 packages in Docker"
echo "3) Show project information"
echo ""
read -p "Enter option [1-3]: " option

case "$option" in
	1)
		echo ""
		echo "Opening GitHub Actions to build packages..."
		echo "Builds are automatically triggered on push to main/master branches"
		echo "Or use 'workflow_dispatch' to trigger manually from GitHub"
		echo ""
		echo "Visit: https://github.com/$(git config remote.origin.url | sed 's/.*://g' | sed 's/.git$//g')/actions"
		;;
	2)
		echo ""
		echo "Testing x86_64 packages..."
		"$SCRIPT_DIR/test.sh" x86_64
		;;
	3)
		echo ""
		echo "=========================================="
		echo "Project Information"
		echo "=========================================="
		echo ""
		echo "Project: UU Game Booster for OpenWRT"
		echo ""
		echo "Package:"
		echo "  - uu-booster: Main package with binary and service"
		echo ""
		echo "Supported Architectures:"
		echo "  - aarch64 (e.g., Raspberry Pi 4, Rockchip)"
		echo "  - arm (e.g., Raspberry Pi 2/3, various ARM boards)"
		echo "  - mipsel (e.g., older routers, MT7620/7621)"
		echo "  - x86_64 (e.g., x86 routers, PCs)"
		echo ""
		echo "Build Options:"
		echo "  1. GitHub Actions - Automatic CI/CD builds (recommended)"
		echo "  2. OpenWRT SDK - Manual build using official SDK"
		echo "  3. scripts/test.sh - Test packages in Docker rootfs"
		echo ""
		echo "Documentation:"
		echo "  - README.md: Full documentation"
		echo "  - docs/BUILD_GUIDE.md: Build instructions"
		echo "  - docs/GETTING_STARTED.md: Quick start guide"
		echo "  - scripts/test.sh: Test script help"
		echo ""
		;;
	*)
		echo "Invalid option"
		exit 1
		;;
esac
