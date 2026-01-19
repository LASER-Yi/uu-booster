# Build Guide

This guide explains how to build UU Booster OpenWRT packages.

## Prerequisites

- Docker (20.10+)
- Docker Compose (v2.0+)
- 5-10GB free disk space
- Internet connection for downloading SDK images and dependencies

## Quick Start

```bash
# Run interactive quick-start script
./scripts/quick-start.sh
```

## Method 1: GitHub Actions (Recommended)

Push to GitHub and the workflow will automatically build generic packages using the official OpenWRT SDK.

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
4. Download the `uu-booster` artifact

Output:
```
 =========================================
Building generic packages
=========================================
Pulling SDK image: openwrt/sdk:x86-64-22.03.7
Building uu-booster package...

=========================================
Build complete!
=========================================

Built packages are in: ./output
-rw-r--r-- 1 user user 45K Jan 18 10:00 uu-booster_1.0.0-1_all.ipk
```

**Note:** Packages are architecture-independent (`_all.ipk`). The UU booster binary is automatically downloaded at install-time based on the router's detected architecture.

## Method 2: GitHub Actions

### Automatic Builds

Push to GitHub and workflow will automatically build the generic packages.

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
4. Download the `uu-booster` artifact

## Testing Packages

### Test in OpenWRT RootFS Docker

You can test the generic packages on any architecture:

```bash
# Test on x86_64 (native, no QEMU required)
./scripts/test.sh x86_64

# Test on aarch64 (requires QEMU)
./scripts/test.sh aarch64

# Test on arm (requires QEMU)
./scripts/test.sh arm

# Test on mipsel (requires QEMU)
./scripts/test.sh mipsel
```

Output:
```
 =========================================
Testing packages on x86_64 rootfs
=========================================
Found package:
  - uu-booster_1.0.0-1_all.ipk

Pulling OpenWRT rootfs: openwrt/rootfs:x86_64

Installing packages...
Updating package lists...
Installing uu-booster...

Verifying installation...

Checking binary:
Binary exists

Checking config:
Config file exists:
version=9.2.10
...

Checking init script:
-rwxr-xr-x 1 root root 218 Jan 18 10:00 /etc/init.d/uu-booster

=========================================
Installation test PASSED!
=========================================
```

## Architecture Support

The generic packages work on any architecture supported by OpenWRT:

- **aarch64** - e.g., Raspberry Pi 4, Rockchip boards
- **arm** - e.g., Raspberry Pi 2/3, various ARM boards
- **mipsel** - e.g., MT7620/7621 routers
- **x86_64** - e.g., x86 routers, PCs

The correct binary is downloaded automatically during package installation.

## Troubleshooting

### Build Failures

**Problem:** `docker pull` fails

**Solution:**
```bash
# Check Docker daemon is running
docker ps

# Check internet connectivity
ping -c 3 downloads.openwrt.org

# Pull manually first
docker pull openwrt/sdk:x86-64-22.03.7
```

**Problem:** Build fails with permission errors

**Solution:**
```bash
# Fix permissions on bin directory
sudo chown -R $USER:$USER bin/

# Run with sudo if needed (not recommended)
sudo ./scripts/build.sh
```

### Package Installation Issues

**Problem:** `opkg` not found on router

**Solution:**
```bash
# Ensure OpenWRT is running
opkg update

# If still not found, check OpenWRT version
cat /etc/openwrt_release
```

**Problem:** Download from UU servers fails

**Solution:**
```bash
# Check UU API is accessible
curl -v http://router.uu.163.com/api/plugin?type=openwrt-x86_64

# Check firewall rules
iptables -L -n

# Try manual download
wget -O /tmp/test.tar.gz http://router.uu.163.com/api/plugin?type=openwrt-x86_64
```

### Service Won't Start

**Problem:** uu-booster service fails to start

**Solution:**
```bash
# Check service status
/etc/init.d/uu-booster status

# View logs
logread | grep uu-booster

# Verify binary exists and is executable
ls -la /usr/sbin/uu/uuplugin
file /usr/sbin/uu/uuplugin

# Check config file
cat /usr/sbin/uu/uu.conf

# Manually test binary
/usr/sbin/uu/uuplugin /usr/sbin/uu/uu.conf
```

## Advanced Usage

### Custom SDK Version

Edit `.github/workflows/build.yml`:
```yaml
- name: Build packages with OpenWRT SDK
  uses: openwrt/gh-action-sdk@v10
  env:
    ARCH: x86_64-23.05.0  # Change version
    PACKAGES: uu-booster
    V: s
```

### Clean Build

```bash
# Remove bin directory
rm -rf bin

# Or use git clean
git clean -fdx

# Rebuild from scratch via GitHub Actions
```

## Development Workflow

### Typical Development Cycle

```bash
# 1. Make changes to package files
vim packages/uu-booster/Makefile

# 2. Commit and push changes (triggers CI)
git add .
git commit -m "Update package version"
git push origin main

# 3. Download artifacts from GitHub Actions
# 4. Test packages locally
./scripts/test.sh x86_64
./scripts/test.sh aarch64
./scripts/test.sh arm
./scripts/test.sh mipsel
```

### Debug Builds

```bash
# Check workflow logs in GitHub Actions
# Enable verbose output by checking V: s environment variable

# For local debugging, download artifacts and test with scripts/test.sh
./scripts/test.sh x86_64
```
```

## Performance Optimization

### Docker BuildKit

Enable Docker BuildKit for faster builds:
```bash
export DOCKER_BUILDKIT=1

# Or add to ~/.docker/config.json
{
  "features": {
    "buildkit": true
  }
}
```

### Cache Docker Images

SDK image is cached locally after first pull:
```bash
# List cached SDK images
docker images | grep openwrt/sdk

# Remove old images to save space
docker image prune -a
```

## Integration with OpenWRT Buildroot

### Add to Existing OpenWRT Build

```bash
# Clone OpenWRT source
git clone https://github.com/openwrt/openwrt.git
cd openwrt

 # Copy package
cp -r ../uu-booster/packages/uu-booster package/

# Update feeds
./scripts/feeds update -a
./scripts/feeds install -a

# Configure and build
make menuconfig
make -j$(nproc)
```

### Create Custom Firmware with UU Booster

 ```bash
# In OpenWRT menuconfig, select:
# Network -> uu-booster

# Build firmware
make
```

## Support

For issues or questions:
1. Check README.md for general documentation
2. Check this build guide for specific problems
3. Open an issue on GitHub with:
   - Build method used
   - Error messages
   - System information (Docker version, OS, etc.)
