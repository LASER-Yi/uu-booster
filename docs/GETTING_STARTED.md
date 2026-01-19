# Getting Started with UU Booster OpenWRT Packages

## Quick Start

The easiest way to get started:

```bash
./scripts/quick-start.sh
```

This will show you an interactive menu with options to build, test, or get more information.

## Build Your First Packages

Push to GitHub and the workflow will automatically build generic packages using the official OpenWRT SDK.

Or trigger the workflow manually:
1. Go to Actions tab in GitHub
2. Select "Build UU Booster Packages" workflow
3. Click "Run workflow"
4. Select branch and click "Run workflow"

The compiled `.ipk` file will be in the `bin/packages/` directory:
- `uu-booster_1.0.0-1_all.ipk` - Generic package

**Note:** These are architecture-independent packages. The correct UU booster binary is downloaded automatically during installation based on your router's architecture.

## Test Packages

Test packages in an OpenWRT Docker container on any platform:

```bash
# Test on x86_64 (native, fastest)
./scripts/test.sh x86_64

# Test on other architectures (requires QEMU)
./scripts/test.sh aarch64
./scripts/test.sh arm
./scripts/test.sh mipsel
```

 ## Documentation

- **README.md** - Main guide
- **docs/BUILD_GUIDE.md** - Build instructions and troubleshooting
- **docs/PROJECT_SUMMARY.md** - Complete overview

## Architecture Support

The generic packages automatically support multiple architectures:

- **aarch64** - e.g., Raspberry Pi 4, Rockchip boards
- **arm** - e.g., Raspberry Pi 2/3, various ARM boards
- **mipsel** - e.g., MT7620/7621 routers
- **x86_64** - e.g., x86 routers, PCs

When you install the package on your router, it automatically detects the architecture and downloads the correct binary.

## Next Steps

1. Read `docs/IMPLEMENTATION.md` for a complete overview
2. Run `./scripts/quick-start.sh` for an interactive menu
3. Build packages via GitHub Actions
4. Test packages: `./scripts/test.sh x86_64`
5. Read `README.md` for installation instructions

## Need Help?

Check documentation files:
- `docs/IMPLEMENTATION.md` - What was created
- `README.md` - Usage and installation
- `docs/BUILD_GUIDE.md` - Build troubleshooting

Happy building!
