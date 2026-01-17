#!/bin/bash
set -e

echo "========================================="
echo "UU Booster - Project Validation"
echo "========================================="
echo ""

required_files=(
	"packages/uu-booster/Makefile"
	"packages/uu-booster/files/control"
	"packages/uu-booster/files/uu-booster.init"
	"packages/luci-app-uu-booster/Makefile"
	"packages/luci-app-uu-booster/luasrc/controller/uu-booster.lua"
	"packages/luci-app-uu-booster/luasrc/model/cbi/uu-booster.lua"
	"packages/luci-app-uu-booster/htdocs/luci-static/resources/view/uu-booster/main.htm"
	"scripts/build.sh"
	"scripts/test.sh"
	"scripts/quick-start.sh"
	"docker-compose.yml"
	"builder/Dockerfile"
	".github/workflows/build.yml"
	"README.md"
	"BUILD_GUIDE.md"
	"PROJECT_SUMMARY.md"
)

missing_files=()

echo "Checking required files..."
for file in "${required_files[@]}"; do
	if [ -f "$file" ]; then
		echo "✓ $file"
	else
		echo "✗ $file (MISSING)"
		missing_files+=("$file")
	fi
done

echo ""
if [ ${#missing_files[@]} -eq 0 ]; then
	echo "========================================="
	echo "All files validated successfully!"
	echo "========================================="
	echo ""
	echo "Next steps:"
	echo "1. Build packages: ./scripts/build.sh x86_64"
	echo "2. Or use quick start: ./scripts/quick-start.sh"
	echo "3. Read docs: cat README.md"
	exit 0
else
	echo "========================================="
	echo "Missing ${#missing_files[@]} file(s)"
	echo "========================================="
	echo ""
	echo "Please ensure all required files are present."
	exit 1
fi
