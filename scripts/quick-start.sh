#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "UU Booster OpenWRT Packages - Quick Start"
echo "=========================================="
echo ""

echo "Choose an option:"
echo "1) Build packages for x86_64 (fastest, host architecture)"
echo "2) Build packages for all architectures"
echo "3) Test x86_64 packages in Docker"
echo "4) Start Docker Compose builder environment"
echo "5) Show project information"
echo ""
read -p "Enter option [1-5]: " option

case "$option" in
	1)
		echo ""
		echo "Building for x86_64..."
		"$SCRIPT_DIR/build.sh" x86_64
		;;
	2)
		echo ""
		echo "Building for all architectures..."
		echo "This may take 10-20 minutes depending on your system"
		read -p "Continue? [y/N] " confirm
		if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
			"$SCRIPT_DIR/build.sh" all
		else
			echo "Aborted"
		fi
		;;
	3)
		echo ""
		echo "Testing x86_64 packages..."
		"$SCRIPT_DIR/test.sh" x86_64
		;;
	4)
		echo ""
		echo "Starting Docker Compose builder..."
		docker-compose up -d
		echo ""
		echo "Builder containers are now running."
		echo "Use 'docker-compose ps' to check status"
		echo "Use 'docker-compose stop' to stop containers"
		;;
	5)
		echo ""
		echo "=========================================="
		echo "Project Information"
		echo "=========================================="
		echo ""
		echo "Project: UU Game Booster for OpenWRT"
		echo ""
		echo "Packages:"
		echo "  - uu-booster: Main package with binary and service"
		echo "  - luci-app-uu-booster: LuCI web interface"
		echo ""
		echo "Supported Architectures:"
		echo "  - aarch64 (e.g., Raspberry Pi 4, Rockchip)"
		echo "  - arm (e.g., Raspberry Pi 2/3, various ARM boards)"
		echo "  - mipsel (e.g., older routers, MT7620/7621)"
		echo "  - x86_64 (e.g., x86 routers, PCs)"
		echo ""
		echo "Build Options:"
		echo "  1. ./scripts/build.sh - Build generic packages"
		echo "  2. docker-compose - Use Docker Compose builder"
		echo "  3. GitHub Actions - Automatic CI/CD builds"
		echo ""
		echo "Documentation:"
		echo "  - README.md: Full documentation"
		echo "  - docs/BUILD_GUIDE.md: Build instructions"
		echo "  - docs/GETTING_STARTED.md: Quick start guide"
		echo "  - scripts/build.sh: Build script help"
		echo "  - scripts/test.sh: Test script help"
		echo ""
		;;
	*)
		echo "Invalid option"
		exit 1
		;;
esac
