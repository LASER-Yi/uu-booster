# Build Guide

This guide explains how to build UU Booster OpenWRT packages using different methods.

## Prerequisites

- Docker (20.10+ with buildx support)
- Docker Compose (v2.0+)
- For cross-architecture builds: QEMU user static binaries
- 5-10GB free disk space
- Internet connection for downloading SDK images and dependencies

## Quick Start

```bash
# Run the interactive quick-start script
./scripts/quick-start.sh
```

## Method 1: Build Script (Recommended)

### Build for Single Architecture

```bash
./scripts/build.sh x86_64
```

Output:
```
=========================================
Building for x86_64 (generic)
=========================================
Pulling SDK image: openwrt/sdk:x86_64-generic-v22.03.7
Building uu-booster package...
Building luci-app-uu-booster package...

Build complete for x86_64
=========================================
All builds complete!
=========================================
Built packages are in: ./output
-rw-r--r-- 1 user user 45K Jan 18 10:00 uu-booster_1.0.0-1_x86_64.ipk
-rw-r--r-- 1 user user 12K Jan 18 10:00 luci-app-uu-booster_1.0.0-1_all.ipk
```

### Build for All Architectures

```bash
./scripts/build.sh all
```

This will build for:
- aarch64 (generic)
- arm (cortex-a7)
- mipsel (24kc)
- x86_64 (generic)

Estimated time: 10-20 minutes depending on your system.

## Method 2: Docker Compose

### Start Builder Containers

```bash
docker-compose up -d
```

This starts 4 builder containers (one for each architecture).

### Build Using Docker Compose

```bash
# Build uu-booster for x86_64
docker-compose exec builder sh -c "
  cp -r /packages/uu-booster /builder/package/ &&
  make package/uu-booster/compile V=s &&
  cp /builder/bin/packages/*/uu-booster_*.ipk /output/
"

# Build luci-app-uu-booster for x86_64
docker-compose exec builder sh -c "
  cp -r /packages/luci-app-uu-booster /builder/package/ &&
  make package/luci-app-uu-booster/compile V=s &&
  cp /builder/bin/packages/*/luci-app-uu-booster_*.ipk /output/
"

# Build for aarch64
docker-compose exec builder-aarch64 sh -c "..."
# Build for arm
docker-compose exec builder-arm sh -c "..."
# Build for mipsel
docker-compose exec builder-mipsel sh -c "..."
```

### Stop Builder Containers

```bash
docker-compose down
```

## Method 3: GitHub Actions

### Automatic Builds

Push to GitHub and the workflow will automatically build packages for all architectures.

### Manual Triggers

1. Go to Actions tab in GitHub
2. Select "Build UU Booster Packages" workflow
3. Click "Run workflow"
4. Select branch and click "Run workflow"

### Download Artifacts

After the workflow completes:
1. Go to Actions tab
2. Select the workflow run
3. Scroll down to "Artifacts" section
4. Download packages for desired architecture

## Testing Packages

### Test in OpenWRT RootFS Docker

```bash
./scripts/test.sh x86_64
```

Output:
```
=========================================
Testing packages for x86_64
=========================================
Found packages:
  - uu-booster_1.0.0-1_x86_64.ipk
  - luci-app-uu-booster_1.0.0-1_all.ipk

Pulling OpenWRT rootfs: openwrt/rootfs:x86_64

Installing packages...
Updating package lists...
Installing uu-booster...
Installing luci-app-uu-booster...

Verifying installation...

Checking binary:
Binary exists

Checking config:
Config file exists:
version=9.2.10
...

Checking init script:
-rwxr-xr-x 1 root root 218 Jan 18 10:00 /etc/init.d/uu-booster

Checking LuCI files:
LuCI files installed

=========================================
Installation test PASSED!
=========================================
```

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
docker pull openwrt/sdk:x86_64-generic-v22.03.7
```

**Problem:** Build fails with permission errors

**Solution:**
```bash
# Fix permissions on output directory
sudo chown -R $USER:$USER output/

# Run with sudo if needed (not recommended)
sudo ./scripts/build.sh x86_64
```

**Problem:** QEMU not found for cross-architecture builds

**Solution:**
```bash
# Install QEMU user static
sudo apt-get update
sudo apt-get install qemu-user-static

# On macOS
brew install qemu

# Verify installation
qemu-aarch64-static --version
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
ls -la /usr/sbin/uu/uu-booster
file /usr/sbin/uu/uu-booster

# Check config file
cat /etc/uu-booster.conf

# Manually test binary
/usr/sbin/uu/uu-booster /etc/uu-booster.conf
```

## Advanced Usage

### Custom SDK Version

Edit `scripts/build.sh`:
```bash
SDK_VERSION="23.05.0"  # Change version
```

Edit `docker-compose.yml`:
```yaml
services:
  builder:
    image: openwrt/sdk:x86_64-generic-v23.05.0
```

### Custom Build Options

Edit `scripts/build.sh`:
```bash
docker run --rm \
  -v "$PROJECT_ROOT/packages:/packages:ro" \
  -v "$PROJECT_ROOT/output:/output" \
  -e TOPDIR=/builder \
  -e "BUILD_LOG=y" \  # Enable build logs
  -e "IGNORE_ERRORS=0" \  # Fail on errors
  "$sdk_image" ...
```

### Clean Build

```bash
# Remove output directory
rm -rf output

# Or use git clean
git clean -fdx

# Rebuild from scratch
./scripts/build.sh x86_64
```

## Development Workflow

### Typical Development Cycle

```bash
# 1. Make changes to package files
vim packages/uu-booster/Makefile

# 2. Build for quick testing
./scripts/build.sh x86_64

# 3. Test the packages
./scripts/test.sh x86_64

# 4. If tests pass, build for all architectures
./scripts/build.sh all

# 5. Test on different architectures (optional)
./scripts/test.sh aarch64
./scripts/test.sh arm
./scripts/test.sh mipsel

# 6. Commit changes
git add .
git commit -m "Update package version"

# 7. Push to GitHub (triggers CI)
git push origin main

# 8. Download artifacts from GitHub Actions
```

### Debug Builds

```bash
# Enable verbose build output
docker run --rm \
  -v "$PROJECT_ROOT/packages:/packages:ro" \
  -v "$PROJECT_ROOT/output:/output" \
  -e TOPDIR=/builder \
  openwrt/sdk:x86_64-generic-v22.03.7 \
  sh -c "make package/uu-booster/compile V=sc"

# Check build logs
ls -la sdk/build_dir/
ls -la sdk/logs/
```

## Performance Optimization

### Parallel Builds

Build for multiple architectures in parallel:
```bash
# Run in background
./scripts/build.sh x86_64 &
./scripts/build.sh aarch64 &
./scripts/build.sh arm &
./scripts/build.sh mipsel &

# Wait for all to complete
wait
```

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

SDK images are cached locally after first pull:
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

# Copy packages
cp -r ../uu-booster/packages/uu-booster package/
cp -r ../uu-booster/packages/luci-app-uu-booster package/

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
# LuCI -> Applications -> luci-app-uu-booster
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
   - Architecture
   - Error messages
   - System information (Docker version, OS, etc.)
