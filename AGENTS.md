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
# - Installs uu-booster and luci-app-uu-booster packages
# - Verifies binary, config, init scripts, and LuCI files are present
# - No unit tests - integration testing only via package installation
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
- **Quoting**: Double-quote all variable expansions to prevent word splitting
- **Comments**: Minimal, only for section headers or complex logic

### Lua (luasrc/**/*.lua)
- **Module declaration**: `module("luci.controller.uu-booster", package.seeall)`
- **Indentation**: TABS (not spaces)
- **Functions**: snake_case names
  ```lua
  function action_check_version()
  function action_update()
  ```
- **Variables**: lowercase `local` declarations
  ```lua
  local arch = luci.sys.exec(...)
  local result = { success = false, message = "" }
  ```
- **HTTP responses**: Always prepare content type first
  ```lua
  luci.http.prepare_content("application/json")
  luci.http.write_json(data)
  ```
- **Error handling**: Check for empty/nil responses, return error objects
  ```lua
  if api_response == "" then
      luci.http.write_json({ success = false, error = "message" })
      return
  end
  ```
- **Pattern matching**: Use `match()` for string extraction
  ```lua
  local download_url = api_response:match("\"url\":\"([^\"]+)\"")
  local version = download_url:match("/v([%d%.]+)/")
  ```

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

### HTML Templates (htdocs/**/*.htm)
- **CSS class names**: hyphenated, prefix with `uu-booster-`
  ```css
  .uu-booster-container { ... }
  .uu-booster-button.primary { ... }
  ```
- **JavaScript**: camelCase functions, `var` for compatibility
  ```javascript
  function checkVersion() { ... }
  function updateBooster() { ... }
  ```
- **XHR**: Use LuCI's XHR wrapper for AJAX
  ```javascript
  XHR.get(url, null, successCallback, errorCallback)
  ```
- **Localization**: Use `<%:Text%>` for translatable strings
- **Error display**: Show messages in div with success/error/info classes

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

### Naming Conventions
- **Packages**: hyphenated lowercase (uu-booster, luci-app-uu-booster)
- **Files**: hyphenated or underscored (uu-booster.init, uu-update)
- **Functions**: snake_case in shell/Lua
- **Variables**: UPPERCASE constants, lowercase locals
- **CSS classes**: hyphenated with component prefix

### Error Handling
- Shell: Check exit codes, use `error_exit()` helper
- Lua: Return error objects with `success` boolean
- Init scripts: Use `|| true` to suppress errors where appropriate
- Always log errors to system logger for debugging

### File Locations
- **Binaries**: `/usr/sbin/uu/uuplugin`
- **Config**: `/usr/sbin/uu/uu.conf`
- **Init scripts**: `/etc/init.d/uu-booster`
- **UCI defaults**: `/etc/uci-defaults/90-uu-booster-firewall`
- **LuCI controller**: `/usr/lib/lua/luci/controller/uu-booster.lua`
- **LuCI model**: `/usr/lib/lua/luci/model/cbi/uu-booster.lua`

### Important Notes
- This is an embedded systems project - avoid unnecessary dependencies
- Packages are architecture-independent (`_all.ipk`) - binary downloaded at runtime
- Always test on multiple architectures if making changes
- No traditional linting/formatters - manual code review required
- Follow OpenWRT package conventions strictly
