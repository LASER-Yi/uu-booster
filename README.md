# UU Game Booster for OpenWRT

OpenWRT package for managing and monitoring UU Game Booster with LuCI web interface.

## Features

- **uu-booster package**: Downloads and manages the uu-booster binary from UU servers
- **luci-app-uu-booster**: Web UI for version management and updates
- Multi-architecture support: aarch64, arm, mipsel, x86_64
- Automatic service management via procd
- Version checking and one-click updates

## Project Structure

```
.
├── packages/
│   ├── uu-booster/              # Main package
│   │   ├── Makefile
│   │   └── files/
│   │       ├── control
│   │       ├── uu-booster.init
│   │       └── (postinst, postrm in Makefile)
│   └── luci-app-uu-booster/      # LuCI interface
│       ├── Makefile
│       └── luasrc/
│           ├── controller/
│           │   └── uu-booster.lua
│           └── model/
│               └── cbi/
│                   └── uu-booster.lua
├── scripts/
│   └── build.sh                  # Build script
├── builder/
│   └── Dockerfile                 # Custom builder (optional)
├── output/                       # Compiled .ipk files
└── docker-compose.yml              # Docker Compose setup
```

## Building

### Option 1: Using build.sh script (Recommended)

Build for specific architecture:
```bash
./scripts/build.sh x86_64
```

Build for all architectures:
```bash
./scripts/build.sh all
```

Available architectures: `aarch64`, `arm`, `mipsel`, `x86_64`

### Option 2: Using Docker Compose

Start the builder containers:
```bash
docker-compose up -d
```

Build for x86_64:
```bash
docker-compose exec builder sh -c "
  cp -r /packages/uu-booster /builder/package/ &&
  make package/uu-booster/compile V=s &&
  cp /builder/bin/packages/*/uu-booster_*.ipk /output/
"

docker-compose exec builder sh -c "
  cp -r /packages/luci-app-uu-booster /builder/package/ &&
  make package/luci-app-uu-booster/compile V=s &&
  cp /builder/bin/packages/*/luci-app-uu-booster_*.ipk /output/
"
```

Build for other architectures:
```bash
# aarch64
docker-compose exec builder-aarch64 sh -c "..."
# arm
docker-compose exec builder-arm sh -c "..."
# mipsel
docker-compose exec builder-mipsel sh -c "..."
```

### Option 3: Using GitHub Actions

Push to GitHub and the workflow will automatically build packages for all architectures.

Generated packages will be available as GitHub Actions artifacts.

## Installation

Transfer the compiled `.ipk` files to your OpenWRT router and install:

```bash
opkg update
opkg install uu-booster_*.ipk
opkg install luci-app-uu-booster_*.ipk
```

## Usage

### Command Line

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
```

### LuCI Web Interface

1. Access OpenWRT LuCI interface (usually `http://192.168.1.1`)
2. Navigate to **Services → UU Booster**
3. View current version and service status
4. Click "Check for Updates" to get the latest version
5. Click "Update to Latest" to download and install updates

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
# Test x86_64 package
docker run --rm -v ./output:/tmp openwrt/rootfs:x86_64 sh -c "
  opkg update &&
  opkg install /tmp/uu-booster_*_x86_64.ipk &&
  opkg install /tmp/luci-app-uu-booster_*_all.ipk
"

# Test other architectures (requires QEMU)
docker run --rm --platform linux/arm/v7 -v ./output:/tmp openwrt/rootfs:arm_cortex-a7 sh -c "..."
```

## Troubleshooting

### Build Fails

1. Ensure Docker is installed and running
2. Check that the SDK image pulls successfully: `docker pull openwrt/sdk:x86-64-22.03.7`
3. Verify package files exist in `packages/` directory

### Download Fails

1. Check internet connectivity
2. Verify UU API is accessible: `curl -v http://router.uu.163.com/api/plugin?type=openwrt-x86_64`
3. Check firewall settings on the router

### Service Won't Start

1. Check logs: `logread | grep uu-booster`
2. Verify binary exists: `ls -la /usr/sbin/uu/uu-booster`
3. Check config file: `cat /etc/uu-booster.conf`
4. Ensure tun module is loaded: `lsmod | grep tun`

## License

This project is based on the UU Game Booster OpenWRT plugin reference implementation.

## Documentation

For detailed documentation, see:
- [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md) - Build instructions
- [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) - Quick start guide
- [docs/PROJECT_SUMMARY.md](docs/PROJECT_SUMMARY.md) - Complete project overview
- [docs/COMPLETE.md](docs/COMPLETE.md) - Implementation status

## References

- [UU Game Booster](https://uu.163.com/)
- [OpenWRT Documentation](https://openwrt.org/docs/)
- [LuCI Documentation](https://github.com/openwrt/luci)
- [Reference Implementation](https://github.com/ttc0419/uuplugin)
