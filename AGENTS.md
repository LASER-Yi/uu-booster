# UU Booster - Agent Development Guide

## Build/Test Commands

### Building Packages
```bash
# Build via GitHub Actions (recommended)
# Push to main/master branch or trigger workflow manually from Actions tab

# Manual build requires OpenWRT SDK
# See .github/workflows/build.yml for reference
```

### Testing
```bash
# Test package installation on specific architecture
./scripts/test.sh x86_64    # Test on x86_64 rootfs (native)
./scripts/test.sh aarch64   # Test on ARM64 (requires QEMU)
./scripts/test.sh arm       # Test on ARM v7 (requires QEMU)
./scripts/test.sh mipsel    # Test on MIPS (requires QEMU)

# The test script:
# - Builds Docker containers with OpenWRT rootfs
# - Installs uu-booster package
# - Verifies binary, config, and init scripts are present
# - No unit tests - integration testing only via package installation

# Test API responses
./scripts/test-api.sh openwrt-x86_64

# Quick start interactive menu
./scripts/quick-start.sh
```

### Local Testing on Router
```bash
# After installing packages
uu check              # Check for updates
uu update             # Update to latest version
uu status             # Show service status
uu restart            # Restart service

# Service management
/etc/init.d/uu-booster start
/etc/init.d/uu-booster stop
/etc/init.d/uu-booster restart
/etc/init.d/uu-booster status
/etc/init.d/uu-booster enable
/etc/init.d/uu-booster disable
```

## Code Style Guidelines

### Shell Scripts (files/*.sh, files/*)
- **Shebang**: `#!/bin/sh` for POSIX compatibility, `#!/bin/bash` for bashisms
- **Indentation**: TABS (not spaces), 1 tab = 4 spaces visually
- **Functions**: snake_case names, lowercase with underscores
  ```bash
  log_message() { ... }
  error_exit() { ... }
  ```
- **Variables**: UPPERCASE for constants, lowercase for local variables
  ```bash
  UU_UPDATE_VERSION="1.0.0"
  local arch=$1
  ```
- **Error handling**: Use `set -e` at script start, explicit exit codes
  ```bash
  if [ $? -ne 0 ]; then
      error_exit "Download failed"
  fi
  ```
- **Logging**: Use `logger` for system logs, `echo` for console
  ```bash
  logger -t uu -p daemon.info "message"
  ```
- **Cleanup**: Always define cleanup function with trap
  ```bash
  cleanup() { rm -rf "$TEMP_DIR" 2>/dev/null; }
  trap cleanup EXIT
  ```
- **Quoting**: Double-quote all variable expansions to prevent word splitting
- **Comments**: Minimal, only for section headers or complex logic

### Makefiles (*/Makefile)
- **Standard OpenWRT package format**
- **Variables**: UPPERCASE for package metadata
  ```makefile
  PKG_NAME:=uu-booster
  PKG_VERSION:=1.0.0
  ```
- **Targets**: Use `define Package/xxx/install` for installation
- **Directories**: Create before installing files
  ```makefile
  $(INSTALL_DIR) $(1)/etc/init.d
  $(INSTALL_BIN) ./files/script $(1)/etc/init.d/script
  ```
- **Architecture**: Set `PKGARCH:=all` for architecture-independent packages
- **Post-install**: Define postinst/postrm for service setup and cleanup

### Init Scripts (files/*.init)
- **Procd format**: `USE_PROCD=1` required
- **Start value**: `START=98` for late startup
- **Service management**:
  ```sh
  procd_open_instance
  procd_set_param command /path/to/binary /path/to/config
  procd_set_param respawn 0 5 0
  procd_set_param stdout 1
  procd_set_param stderr 1
  procd_close_instance
  ```

### UCI Defaults (files/*)
- **Check existing config**: Always verify before creating
  ```sh
  if uci get firewall.uu >/dev/null 2>&1; then
      exit 0  # Already configured
  fi
  ```
- **Set values**: Use uci set commands
  ```sh
  uci set firewall.uu='zone'
  uci set firewall.uu.name='uu'
  uci commit firewall
  ```
- **Reload services**: Call service reload after commit
  ```sh
  /etc/init.d/firewall reload >/dev/null 2>&1
  ```

### Naming Conventions
- **Packages**: hyphenated lowercase (uu-booster)
- **Files**: hyphenated or underscored (uu-booster.init, uu-update)
- **Functions**: snake_case in shell/Lua
- **Variables**: UPPERCASE constants, lowercase locals
- **UCI sections**: lowercase with underscores (lan_to_uu, uu_to_lan)

### Error Handling
- **Shell**: Check exit codes, use `error_exit()` helper
- **Lua**: Return error objects with `success` boolean
- **Init scripts**: Use `|| true` to suppress errors where appropriate
- **API calls**: Validate response before processing
  ```bash
  RESPONSE=$(curl -s "$URL")
  if [ -z "$RESPONSE" ]; then
      error_exit "No response from API"
  fi
  ```
- **Always log errors** to system logger for debugging

### File Locations
- **Binaries**: `/usr/sbin/uu/uuplugin`
- **Config**: `/usr/sbin/uu/uu.conf`
- **Init scripts**: `/etc/init.d/uu-booster`
- **UCI defaults**: `/etc/uci-defaults/90-uu-booster-firewall`
- **UUID backup**: `/etc/uu/.uuplugin_uuid`

### Important Notes
- This is an embedded systems project - avoid unnecessary dependencies
- Packages are architecture-independent (`_all.ipk`) - binary downloaded at runtime
- Always test on multiple architectures if making changes
- No traditional linting/formatters - manual code review required
- Follow OpenWRT package conventions strictly
- Use `logger -t uu` for consistent logging prefix
