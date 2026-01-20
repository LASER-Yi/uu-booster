# Architecture

This document describes the technical architecture of the UU Booster OpenWRT package.

## Package Structure

The project is organized as follows:

```
uu-booster/
├── packages/
│   ├── uu-booster/              # Main package
│   │   ├── Makefile            # OpenWRT package build definition
│   │   └── files/
│   │       ├── control         # Package metadata
│   │       ├── uu-booster.init # Service management script (procd)
│   │       ├── uu              # Management CLI script
│   │       ├── uu-common       # Shared library for common functions
│   │       └── 90-uu-booster-firewall  # UCI firewall configuration
│   └── luci-app-uu-booster/     # Optional LuCI web interface
│       ├── Makefile            # OpenWRT package build definition
│       ├── htdocs/
│       │   └── luci-static/
│       │       └── resources/
│       │           └── view/
│       │               └── uu-booster/
│       │                   └── overview.js  # Frontend view
│       └── root/
│           └── usr/
│               ├── libexec/
│               │   └── rpcd/
│               │       └── uu-booster       # RPC backend
│               └── share/
│                   ├── luci/
│                   │   └── menu.d/
│                   │       └── luci-app-uu-booster.json  # Menu config
│                   └── rpcd/
│                       └── acl.d/
│                           └── luci-app-uu-booster.json  # ACL permissions
├── scripts/
│   ├── test.sh                # Package installation testing
│   ├── download-uu.sh         # Manual binary download utility
│   ├── test-api.sh            # API response testing
│   └── quick-start.sh         # Interactive menu
├── .github/workflows/
│   └── build.yml              # GitHub Actions CI/CD pipeline
├── docs/                      # Documentation
└── README.md                  # Project documentation
```

## Design Decisions

### Generic Package Approach

**Decision**: Use a single architecture-independent package (`_all.ipk`)

**Benefits:**
- Single build for all architectures
- Faster CI/CD pipeline
- Simpler release management
- Reduces build artifacts and storage

**Trade-offs:**
- Binary downloaded at install-time (not included in package)
- Requires internet connectivity during installation
- Depends on NetEase API availability

**Rationale:**
The NetEase UU plugin provides architecture-specific binaries for aarch64, arm, mipsel, and x86_64. OpenWRT routers always have internet access when installing packages, making runtime download acceptable. This approach significantly reduces build complexity and maintenance overhead.

### MD5 Validation

**Decision**: Implement MD5 checksum validation with primary and backup URL support

**Benefits:**
- Ensures downloaded file integrity
- Prevents corrupted or tampered binaries
- Automatic failover to backup URL
- Clear error messages for debugging

**Implementation:**
1. Query UU API to get download URL and expected MD5
2. Download binary from primary URL
3. Calculate MD5 of downloaded file
4. Compare with expected MD5
5. If mismatch, retry with backup URL
6. Report detailed status at each step

**Files:**
- `packages/uu-booster/Makefile` - Post-install script with validation logic
- `scripts/download-uu.sh` - Standalone download utility

### Service Management

**Decision**: Use OpenWRT's procd for service management

**Benefits:**
- Native OpenWRT integration
- Automatic respawn on failure
- Standard service management interface
- Built-in logging support

**Configuration:**
- Start priority: 98 (late startup)
- Respawn: 0 5 0 (no respawn delay, max 5 times in 0 seconds, then stop)
- Stdout/stderr: Enabled for logging
- Watchdog: Not configured

**Files:**
- `packages/uu-booster/files/uu-booster.init` - Procd init script

### Firewall Configuration

**Decision**: Automatic firewall rule setup via UCI defaults

**Benefits:**
- Zero manual configuration
- Consistent across installations
- Easy to remove (automatic cleanup)
- Follows OpenWRT conventions

**Rules Created:**
- UU zone with masquerading
- Forwarding from LAN to UU
- Forwarding from UU to LAN
- Appropriate INPUT/OUTPUT/FORWARD policies

**Files:**
- `packages/uu-booster/files/90-uu-booster-firewall` - UCI defaults script

## File Locations

### Installation Paths

When installed, the package places files in these locations:

| File | Path | Purpose |
|------|------|---------|
| Binary | `/usr/sbin/uu/uuplugin` | UU plugin executable (downloaded) |
| Configuration | `/usr/sbin/uu/uu.conf` | Plugin configuration file |
| UUID | `/usr/sbin/uu/.uuplugin_uuid` | Device identifier (preserved on reinstall) |
| Init Script | `/etc/init.d/uu-booster` | Service management script |
| Management CLI | `/usr/bin/uu` | Command-line interface |
| Shared Library | `/usr/lib/uu-common` | Common functions for uu and RPC backend |
| Firewall Defaults | `/etc/uci-defaults/90-uu-booster-firewall` | Initial firewall configuration |
| RPC Backend | `/usr/libexec/rpcd/uu-booster` | LuCI RPC interface backend |
| LuCI View | `/usr/share/luci/static/resources/view/uu-booster/overview.js` | Frontend view |
| Menu Config | `/usr/share/luci/menu.d/luci-app-uu-booster.json` | LuCI menu entry |
| ACL Config | `/usr/share/rpcd/acl.d/luci-app-uu-booster.json` | RPC permissions |

### Backup Locations

On package removal:
- Device UUID is backed up to `/etc/uu/.uuplugin_uuid` for future reinstalls

## Architecture Detection

### Detection Method

The package detects router architecture by reading `/etc/openwrt_release`:

```bash
ARCH=$(grep '^DISTRIB_ARCH' /etc/openwrt_release | awk -F "'" '{print $2}')
```

### Mapping Table

OpenWRT architecture names are mapped to UU API parameters:

| OpenWRT Arch | UU API Parameter | Example Devices |
|--------------|------------------|-----------------|
| aarch64_* | openwrt-aarch64 | Raspberry Pi 4, Rockchip boards |
| arm_* | openwrt-arm | Raspberry Pi 2/3, ARMv7 boards |
| mipsel_* | openwrt-mipsel | MT7620/7621, MediaTek routers |
| x86_64 | openwrt-x86_64 | x86 routers, PCs |

### Detection Logic

```bash
# Extract architecture
ARCH=$(grep '^DISTRIB_ARCH' /etc/openwrt_release | awk -F "'" '{print $2}')

# Map to API parameter (strip sub-architecture suffix)
UU_ARCH="${ARCH%%-*}"

# Query UU API
curl -s "http://router.uu.163.com/api/plugin?type=openwrt-${UU_ARCH}"
```

## Dependencies

### Required OpenWRT Packages

| Package | Purpose | Version |
|---------|---------|--------|
| kmod-tun | TUN/TAP device support | Any |
| iptables | Firewall rules | OpenWRT 21.03+ |
| uci | Configuration management | OpenWRT 21.03+ |

### Required Kernel Modules

| Module | Purpose |
|--------|---------|
| tun | TUN device for UU plugin |

### Runtime Dependencies

These are NOT package dependencies but are required for operation:
- Internet connectivity (for initial binary download)
- OpenWRT 21.03 or higher (tested on 24.10.1)
- Sufficient disk space (~5MB)

## Build Pipeline

### GitHub Actions Workflow

The project uses GitHub Actions for CI/CD:

**Workflow**: `.github/workflows/build.yml`

**Trigger Conditions:**
- Push to main/master branch
- Pull requests
- Manual workflow trigger

**Build Process:**
1. Checkout repository
2. Setup OpenWRT SDK (uses official action v10)
3. Cache feeds for faster builds
4. Build packages for all architectures (single generic package)
5. Upload artifacts

**Artifacts:**
- `uu-booster_1.0.0-1_all.ipk` - Generic package

**Releases:**
- Automatic release creation on git tags
- Artifacts attached to releases

### Manual Build

For local builds, see [BUILD_GUIDE](BUILD_GUIDE.md).

## Data Flow

### Installation Flow

```
1. User installs package (opkg install)
   ↓
2. Package postinst script runs
   ↓
3. Detect router architecture
   ↓
4. Query UU API for binary URL and MD5
   ↓
5. Download binary from primary URL
   ↓
6. Validate MD5 checksum
   ├─ Match → Install and start service
   └─ Mismatch → Try backup URL
                 ↓
                 Match → Install and start service
                 ↓
                 Fail → Error message
```

### Update Flow

```
1. User runs: uu check or uu update
   ↓
2. Script queries UU API for version
   ↓
3. Compare with current version
   ├─ Same → No update needed
   └─ New → Download process
            ↓
            Download binary
            ↓
            Validate MD5
            ↓
            Stop service
            ↓
            Replace binary
            ↓
            Start service
```

### Service Management Flow

```
1. User runs service command (start/stop/restart)
   ↓
2. uu script calls init script
   ↓
3. Init script uses procd commands
   ↓
4. procd manages process lifecycle
   ↓
5. Status returned to user
```

## Error Handling

### Download Errors

- **Primary URL fails**: Automatic fallback to backup URL
- **Both URLs fail**: Clear error message logged to system log
- **MD5 mismatch**: Retry with backup URL, report error if both fail
- **No internet connection**: Error message with troubleshooting tips

### Service Errors

- **Binary not found**: Clear error, suggest running `uu update`
- **Missing dependencies**: Check for kmod-tun, suggest installation
- **Startup failure**: Log detailed error, check for conflicts

### Validation Errors

- **Corrupted package**: Clear error message
- **Missing files**: Validate all required files present
- **Permission issues**: Check file permissions, fix if possible

## Security Considerations

### Binary Integrity

- MD5 checksum verification for all downloads
- Downloads only from official NetEase servers
- No code execution from untrusted sources

### File Permissions

- Binary: executable (755)
- Configuration: readable by root only (600)
- Init script: executable (755)

### Network Security

- Downloads over HTTP (official UU API)
- No user credentials stored in plain text
- Device UUID preserved but not exposed

## Performance Considerations

### Resource Usage

- **Memory**: Typically 10-50MB depending on number of connected devices
- **CPU**: Low idle usage, spikes during connection setup
- **Disk**: ~5MB for binary and configuration

### Scalability

- Designed for home/small office routers
- Supports multiple simultaneous devices
- No hard limit on concurrent connections (depends on UU plugin limits)

## Future Considerations

### Potential Improvements

1. **nftables Support**: Add support for nftables (OpenWRT 22.03+)
2. **Health Monitoring**: Built-in health checks and metrics
3. **Rollback Support**: Ability to rollback to previous binary version
4. **Download Cache**: Local cache of downloaded binaries

### Architecture Expansion

Possible future architecture support:
- mips (not mipsel) - if NetEase adds support
- Other ARM variants - if NetEase adds support

## References

- [OpenWRT Package Development Guide](https://openwrt.org/docs/guide-developer/packages)
- [Procd Documentation](https://openwrt.org/docs/guide-developer/procd)
- [UCI Configuration System](https://openwrt.org/docs/guide-user/base-system/uci)
