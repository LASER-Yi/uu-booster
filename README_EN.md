# UU Booster for OpenWRT

OpenWRT management tool for UU Game Booster - Unofficial implementation

## Project Overview

This project provides a convenient management solution for UU Game Booster on OpenWRT routers. With a single installation package, it automatically downloads and configures the official UU plugin.

## Key Features

- **Easy Management** - One-click install, start, stop, update UU plugin
- **Automatic Architecture Detection** - Detects router architecture and downloads correct official binary
- **Multi-Architecture Support** - Single package supports aarch64, arm, mipsel, x86_64
- **Secure Validation** - MD5 checksum verification ensures file integrity
- **Failover Support** - Automatic fallback to backup URL, retry on failure
- **Service Management** - Integrated with OpenWRT procd
- **Firewall Configuration** - Automatic firewall rule setup
- ⚠️ **Testing Disclaimer** - Only tested on OpenWRT 24.10.1, other versions may require adaptation

## Supported Devices

- **aarch64**: Raspberry Pi 4, Rockchip boards, ARM64 routers
- **arm**: Raspberry Pi 2/3, various ARMv7 boards
- **mipsel**: MT7620/7621, MediaTek routers
- **x86_64**: x86 routers, PCs running OpenWRT

## Quick Installation

### Method 1: LuCI Web Interface (Easiest)

1. Log in to your OpenWRT router's LuCI web interface (usually http://192.168.1.1)
2. Navigate to "System" → "Software"
3. Click "Upload package"
4. Select the downloaded `uu-booster_*.ipk` file and upload
5. Click "Install"
6. The service will start automatically after installation completes

### Method 2: From GitHub Releases (Recommended)

⚠️ **Note**: This project has only been tested on OpenWRT 24.10.1. If you encounter issues on other versions, please open an Issue.

1. Download the package for your architecture
2. Transfer to your OpenWRT router
3. SSH into the router and install:

```bash
opkg install uu-booster_*.ipk
```

The package will automatically:
- Detect your router's architecture
- Download the correct binary from NetEase servers
- Configure firewall rules
- Start the service

## Quick Start

After installation, manage UU Booster with simple commands:

```bash
# Check service status
uu status

# Check for updates
uu check

# Update to latest version
uu update

# Restart service
uu restart
```

## Documentation

- [Installation Guide](docs/user/INSTALLATION.md) - Detailed installation instructions
- [Usage Guide](docs/user/USAGE.md) - CLI commands and configuration
- [Troubleshooting](docs/user/TROUBLESHOOTING.md) - Common issues and solutions

## References

- [ttc0419/uuplugin](https://github.com/ttc0419/uuplugin) - Reference implementation
- [luci-app-uugamebooster](https://github.com/coolsnowwolf/luci/tree/master/applications/luci-app-uugamebooster) - LuCI web interface

## AI Usage

Most of the code in this project was written with AI assistance, including:
- OpenWRT package management scripts
- GitHub Actions workflow configuration
- Documentation writing and maintenance
- Testing scripts and utilities

While the code has been manually reviewed, there may be undiscovered issues. If you encounter any unexpected behavior during usage, please:
1. Check the [Troubleshooting Guide](docs/user/TROUBLESHOOTING.md)
2. Open an [Issue on GitHub](https://github.com/LASER-Yi/uu-booster/issues)
3. Provide detailed error information and system environment

Your feedback helps improve this project!

## License

[License](LICENSE)
