# Testing

## ⚠️ Testing Disclaimer

This project has been tested on OpenWRT 24.10.1 (x86_64 architecture only). While test scripts support multiple architectures (aarch64, arm, mipsel, x86_64), full testing on all architectures has not been completed.

**Verified Working:**
- OpenWRT Version: 24.10.1
- Architecture: x86_64
- Status: ✅ Installation, service startup, and basic operations verified

**Untested Architectures:**
The following architectures are supported by the code but have not been fully tested:
- aarch64
- arm
- mipsel

If you successfully test on these architectures, please report your results by opening an Issue on GitHub!

---

## Local Testing

### Test Script Usage

The project includes a comprehensive test script that verifies package installation on different OpenWRT architectures using Docker containers.

```bash
# Test on x86_64 (native, fastest - no QEMU required)
./scripts/test.sh x86_64

# Test on aarch64 (requires QEMU)
./scripts/test.sh aarch64

# Test on arm (requires QEMU)
./scripts/test.sh arm

# Test on mipsel (requires QEMU)
./scripts/test.sh mipsel
```

### What Gets Tested

The test script verifies:

1. **Package Availability**
   - Checks if `.ipk` file exists in output directory

2. **Package Installation**
   - Uses OpenWRT RootFS Docker container
   - Runs `opkg install` with the package
   - Checks for installation errors

3. **Binary Installation**
   - Verifies `/usr/sbin/uu/uuplugin` exists
   - Checks file is executable
   - Validates binary format

4. **Configuration Files**
   - Confirms `/usr/sbin/uu/uu.conf` exists
   - Verifies configuration content
   - Checks file permissions

5. **Init Scripts**
   - Verifies `/etc/init.d/uu-booster` exists
   - Checks script is executable
   - Validates script format

6. **Firewall Configuration**
   - Confirms UCI defaults script exists
   - Verifies firewall rules are applied

### Test Output Example

**Successful Test:**
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
Configuring uu-booster.

Verifying installation...

Checking binary:
Binary exists
Binary is executable

Checking config:
Config file exists:
version=9.2.10
...
Config file permissions correct

Checking init script:
-rwxr-xr-x 1 root root 341 Jan 19 00:00 /etc/init.d/uu-booster

Checking firewall defaults:
Firewall defaults script exists

=========================================
Installation test PASSED!
=========================================
```

### Prerequisites for Testing

**Docker Setup:**
```bash
# Install Docker (if not already installed)
# On macOS: Download from docker.com
# On Linux: sudo apt install docker.io

# Verify Docker is running
docker ps

# For non-x86_64 testing, install QEMU
# On Ubuntu/Debian:
sudo apt install qemu-user-static

# Register QEMU binfmt
docker run --privileged --rm tonistiigi/binfmt --install all
```

### Troubleshooting Tests

**Problem: Docker image pull fails**
```bash
# Check internet connection
ping -c 3 hub.docker.com

# Try pulling manually
docker pull openwrt/rootfs:x86_64
```

**Problem: QEMU not available for ARM/MIPS**
```bash
# Install QEMU static binaries
sudo apt install qemu-user-static

# Register with Docker
docker run --privileged --rm tonistiigi/binfmt --install all
```

**Problem: Permission denied errors**
```bash
# Check Docker permissions
groups | grep docker

# Add user to docker group (if not already)
sudo usermod -aG docker $USER

# Logout and login again
```

---

## CI/CD Testing

### GitHub Actions Workflow

The project uses GitHub Actions for automated testing and building.

**Workflow File:** `.github/workflows/build.yml`

**Testing Process:**

1. **Environment Setup**
   - Checkout repository
   - Setup OpenWRT SDK
   - Cache feeds for faster builds

2. **Package Build**
   - Build generic package (`_all.ipk`)
   - Verify build artifacts

3. **Artifact Upload**
   - Upload `.ipk` files as workflow artifacts
   - Attach to releases on tag push

**Manual Trigger:**
1. Go to GitHub Actions tab
2. Select "Build UU Booster Packages" workflow
3. Click "Run workflow"
4. Select branch and run

**Accessing Artifacts:**
1. Go to Actions tab
2. Select completed workflow run
3. Download "uu-booster" artifact

### Continuous Integration

The workflow runs automatically on:
- Push to main/master branch
- Pull requests
- Manual triggers

This ensures code changes are always tested before merging.

---

## Manual Testing

### Test Scripts in scripts/ Directory

#### test-api.sh

Tests API response parsing for all supported architectures.

```bash
./scripts/test-api.sh
```

**What it tests:**
- API connectivity to NetEase servers
- JSON parsing for URL, MD5, and backup URL fields
- Response validation
- Architecture-to-API-parameter mapping

**Output:**
```
Testing API for openwrt-aarch64...
✓ URL extracted: http://...
✓ MD5: 768cd1bc4ddee165d5aea91f4d03427a
✓ Backup URL available: http://...

Testing API for openwrt-arm...
...
```

#### download-uu.sh

Manually download UU booster binary for testing.

```bash
# Download specific architecture
./scripts/download-uu.sh openwrt-x86_64

# Output file: /tmp/uuplugin-openwrt-x86_64.tar.gz
```

**Usage:**
- Useful for testing downloads without full package installation
- Can extract and inspect binary content
- Helps debug download issues

#### validate.sh

Validate all project files for consistency.

```bash
./scripts/validate.sh
```

**What it checks:**
- Package Makefile syntax
- Required files presence
- File permissions
- Configuration consistency
- Documentation completeness

**Output:**
```
Validating project files...

Checking package structure...
✓ Makefile exists
✓ files directory exists
✓ control file exists

Checking file contents...
✓ control: Package name correct
✓ control: Version format correct
✓ init script valid

Project validation PASSED
```

---

## Integration Testing

### Testing on Real Hardware

For production deployment, test on actual router hardware:

**Preparation:**
1. Build package or download from CI artifacts
2. Transfer to router using SCP
3. SSH into router

**Installation Test:**
```bash
# Install package
opkg install /tmp/uu-booster_*.ipk

# Check installation
ls -la /usr/sbin/uu/uuplugin
cat /usr/sbin/uu/uu.conf

# Check service
/etc/init.d/uu-booster status
logread | grep uu-booster
```

**Functional Test:**
```bash
# Check service
uu status

# Check for updates
uu check

# Test update (if available)
uu update

# Test restart
uu restart
```

**Firewall Test:**
```bash
# Check firewall rules
uci show firewall.uu
iptables -L -n | grep uu

# Test connectivity
ping -c 3 8.8.8.8
```

---

## Performance Testing

### Monitoring Resource Usage

**CPU Usage:**
```bash
# Monitor CPU usage over time
top -d 5 | grep uuplugin

# Check during active gaming
```

**Memory Usage:**
```bash
# Check memory usage
ps aux | grep uuplugin
free -h
```

**Network Performance:**
```bash
# Check throughput
iperf3 -c <server_ip>

# Monitor connections
netstat -an | grep uuplugin
```

### Stress Testing

**Multiple Devices:**
- Connect multiple devices simultaneously
- Monitor service stability
- Check if all devices receive acceleration

**Long-running Test:**
- Run service for 24+ hours
- Monitor for memory leaks
- Check for crashes or respawns

**Update Cycle Test:**
- Run multiple update cycles
- Verify service stability after each update
- Check configuration preservation

---

## Regression Testing

### Version Compatibility

Test across OpenWRT versions (if possible):

**Test Matrix:**
| OpenWRT Version | Architecture | Status |
|-----------------|--------------|--------|
| 24.10.1 | x86_64 | ✅ Tested |
| 23.05.0+ | Any | ⚠️ Needs testing |
| 22.03.0+ | Any | ⚠️ Needs testing |
| 21.03.0+ | Any | ⚠️ Needs testing |

### Architecture Compatibility

Test all supported architectures:

| Architecture | Status | Notes |
|--------------|--------|-------|
| x86_64 | ✅ Tested | Works on 24.10.1 |
| aarch64 | ⏳ Untested | Code supports it |
| arm | ⏳ Untested | Code supports it |
| mipsel | ⏳ Untested | Code supports it |

---

## Reporting Test Results

### How to Report

If you test on untested combinations, please report results:

1. **Open an Issue** on GitHub: https://github.com/LASER-Yi/uu-booster/issues
2. **Use this template:**

```markdown
## Test Report

### Environment
- OpenWRT Version: [output of `cat /etc/openwrt_release`]
- Router Model: [your router model]
- Architecture: [output of `cat /etc/openwrt_release | grep DISTRIB_ARCH`]
- Package Version: [version number]

### Tests Performed
- [ ] Package installation
- [ ] Service startup
- [ ] Service status check
- [ ] Update check
- [ ] Update execution (if update available)
- [ ] Service restart
- [ ] Firewall rules

### Results
**Installation:** [PASSED/FAILED]
**Service:** [PASSED/FAILED]
**Updates:** [PASSED/FAILED]
**Firewall:** [PASSED/FAILED]

### Issues Encountered
[Any issues or error messages]

### Additional Notes
[Any other observations]
```

### Verification Checklist

Before reporting, ensure:

- [ ] Package installed without errors
- [ ] Binary downloaded successfully
- [ ] Service starts on boot
- [ ] Service runs without crashes
- [ ] Updates work correctly
- [ ] Firewall rules applied
- [ ] Gaming performance improved (if applicable)

---

## Debugging Failed Tests

### Common Failures

**Download Fails:**
```bash
# Check API connectivity
curl http://router.uu.163.com/api/plugin?type=openwrt-x86_64

# Check DNS
nslookup router.uu.163.com

# Check firewall
iptables -L OUTPUT -n -v
```

**Service Won't Start:**
```bash
# Check binary
ls -la /usr/sbin/uu/uuplugin
file /usr/sbin/uu/uuplugin

# Check tun module
lsmod | grep tun

# Check logs
logread | grep uu-booster

# Try manually
/usr/sbin/uu/uuplugin /usr/sbin/uu/uu.conf
```

**Update Fails:**
```bash
# Check current version
uu status

# Check API
./scripts/test-api.sh

# Manual update
uu update

# Check logs
logread | grep uu
```

---

## Test Coverage

### Current Coverage

- ✅ Package installation (x86_64 on 24.10.1)
- ✅ Service management (start/stop/restart)
- ✅ Binary download
- ✅ MD5 validation
- ✅ Firewall configuration
- ✅ Update mechanism

### Missing Coverage

- ❌ Installation on aarch64
- ❌ Installation on arm
- ❌ Installation on mipsel
- ❌ Testing on OpenWRT 23.05
- ❌ Testing on OpenWRT 22.03
- ❌ Testing on OpenWRT 21.03
- ❌ Long-running stability tests
- ❌ Performance benchmarks
- ❌ Multi-device stress tests

### Priority Areas

**High Priority:**
1. Test on aarch64 (common for modern routers)
2. Test on mipsel (common for budget routers)
3. Test on OpenWRT 23.05

**Medium Priority:**
1. Test on OpenWRT 22.03
2. Long-running stability tests

**Low Priority:**
1. Performance benchmarks
2. Stress testing

---

## Contributing Test Results

We welcome community testing! If you test this project on different hardware or OpenWRT versions, please:

1. **Report results** - Open an issue with test results
2. **Provide details** - Include version, architecture, router model
3. **Document issues** - Report any problems encountered
4. **Suggest improvements** - Ideas for better testing

Your feedback helps improve compatibility and reliability for everyone!
