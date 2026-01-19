# UU Game Booster for OpenWRT

OpenWRT package for managing and monitoring UU Game Booster.

## Features

- Downloads and manages the uu-booster binary from UU servers
- Multi-architecture support: aarch64, arm, mipsel, x86_64
- Automatic service management via procd
- Version checking and updates via command line

## Project Structure

```
.
├── packages/
│   └── uu-booster/              # Main package
│       ├── Makefile
│       └── files/
│           ├── control
│           ├── uu-booster.init
│           ├── uu-update
│           └── (postinst, postrm in Makefile)
├── scripts/
│   └── test.sh                  # Test script
└── bin/                          # Build artifacts (generated)
```

## Building

### Using GitHub Actions (Recommended)

Push to GitHub and the workflow will automatically build generic packages using the official OpenWRT SDK.

**Note:** Packages are architecture-independent (`_all.ipk`). The UU booster binary is automatically downloaded at install-time based on the router's detected architecture.

### Manual Triggers

1. Go to Actions tab in GitHub
2. Select "Build UU Booster Packages" workflow
3. Click "Run workflow"
4. Select branch and click "Run workflow"

### Download Artifacts

After workflow completes:
1. Go to Actions tab
2. Select workflow run
3. Scroll down to "Artifacts" section
4. Download packages

## Installation

Transfer the compiled `.ipk` files to your OpenWRT router and install:

```bash
opkg update
opkg install uu-booster_*.ipk
```

## Usage

```bash
# Start service
/etc/init.d/uu-booster start

# Stop service
/etc/init.d/uu-booster stop

# Restart service
/etc/init.d/uu-booster restart

# Check status
/etc/init.d/uu-booster status

# Enable on boot
/etc/init.d/uu-booster enable

# Disable on boot
/etc/init.d/uu-booster disable

# Check for updates
/usr/bin/uu-update check

# Update to latest version
/usr/bin/uu-update update
```

## Architecture Support

The package automatically detects the router's architecture and downloads the appropriate binary:

| OpenWRT Arch | UU API Parameter |
|---------------|------------------|
| aarch64_*     | openwrt-aarch64 |
| arm_*          | openwrt-arm |
| mipsel_*       | openwrt-mipsel |
| x86_64         | openwrt-x86_64 |

## Testing

### Using OpenWRT RootFS Docker

```bash
# Test generic packages on any architecture
./scripts/test.sh x86_64
./scripts/test.sh aarch64
./scripts/test.sh arm
./scripts/test.sh mipsel
```

## Troubleshooting

### Build Fails

1. Ensure you're pushing to `main` or `master` branch, or trigger workflow manually
2. Check workflow logs in GitHub Actions tab
3. Verify package Makefiles exist in `packages/` directory

### Download Fails

1. Check internet connectivity
2. Verify UU API is accessible: `curl -v http://router.uu.163.com/api/plugin?type=openwrt-x86_64`
3. Check firewall settings on the router

### Service Won't Start

1. Check logs: `logread | grep uu-booster`
2. Verify binary exists: `ls -la /usr/sbin/uu/uuplugin`
3. Check config file: `cat /usr/sbin/uu/uu.conf`
4. Ensure tun module is loaded: `lsmod | grep tun`

## Documentation

For detailed documentation, see:
- [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md) - Build instructions
- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) - Quick start guide
- [docs/PROJECT_SUMMARY.md](docs/PROJECT_SUMMARY.md) - Complete project overview

## References

- [Reference Implementation](https://github.com/ttc0419/uuplugin)

