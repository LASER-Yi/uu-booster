# JSON API Fix

## Issue

The UU API returns JSON format, not plain text. This caused the initial implementation to fail when extracting download URLs.

### Original Problem

The API response format:
```json
{"md5":"768cd1bc4ddee165d5aea91f4d03427a","output":null,"signature":null,"status":"ok","url":"http://uurouter.gdl.netease.com/uuplugin/openwrt-x86_64/v10.15.16/uu.tar.gz?key1=b4cd2ded4c51e64d6ab86e31b3e2b8fb&key2=696bdb24","url_bak":"http://uurouter.gdl04.netease.com/..."}
```

The original code used:
```bash
curl -s -H "Accept:text/plain" "http://router.uu.163.com/api/plugin?type=openwrt-$ARCH" | awk -F ',' '{print $1}'
```

This would incorrectly parse as it expects comma-delimited text, not JSON.

## Solution

Updated to use `sed` for JSON parsing:

```bash
curl -s "http://router.uu.163.com/api/plugin?type=openwrt-$ARCH" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p'
```

This extracts the `url` field value from the JSON response.

## Files Updated

### 1. Main Package Makefile
**File:** `packages/uu-booster/Makefile`

**Line 71:**
```bash
# OLD
DOWNLOAD_URL=$$(curl -s -H "Accept:text/plain" "http://router.uu.163.com/api/plugin?type=openwrt-$$UU_ARCH" | awk -F ',' '{print $$1}')

# NEW
DOWNLOAD_URL=$$(curl -s "http://router.uu.163.com/api/plugin?type=openwrt-$$UU_ARCH" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
```

### 2. LuCI Controller
**File:** `packages/luci-app-uu-booster/luasrc/controller/uu-booster.lua`

**Line 22 (action_check_version):**
```lua
-- OLD
local download_url = luci.sys.exec("curl -s -H 'Accept:text/plain' 'http://router.uu.163.com/api/plugin?type=openwrt-" .. uu_arch .. "' | awk -F ',' '{print $1}'")

-- NEW
local download_url = luci.sys.exec("curl -s 'http://router.uu.163.com/api/plugin?type=openwrt-" .. uu_arch .. "' | sed -n 's/.*\"url\":\"\\([^\"]*\\)\".*/\\1/p'")
```

**Line 93 (action_update):**
```lua
-- OLD
local download_url = luci.sys.exec("curl -s -H 'Accept:text/plain' 'http://router.uu.163.com/api/plugin?type=openwrt-" .. uu_arch .. "' | awk -F ',' '{print $1}'")

-- NEW
local download_url = luci.sys.exec("curl -s 'http://router.uu.163.com/api/plugin?type=openwrt-" .. uu_arch .. "' | sed -n 's/.*\"url\":\"\\([^\"]*\\)\".*/\\1/p'")
```

## New Scripts

### 1. download-uu.sh
Downloads UU booster binary for testing purposes.

**Usage:**
```bash
./scripts/download-uu.sh openwrt-x86_64
```

**Features:**
- Queries UU API
- Parses JSON response
- Downloads tar.gz to `/tmp/uu-booster.tar.gz`
- Shows download status

### 2. test-api.sh
Tests API response parsing for all architectures.

**Usage:**
```bash
./scripts/test-api.sh
```

**Features:**
- Tests all 4 architectures
- Shows API responses
- Validates URL extraction
- Compares old vs new parsing methods

## Testing

Run the API test script:
```bash
./scripts/test-api.sh
```

Expected output:
```
=========================================
UU API JSON Parsing Test
=========================================

Testing API response parsing...

--- Testing: openwrt-aarch64 ---
Response:
{"md5":"3d08d8ca3a7855cf5dd421b96a26302d",...

✓ URL extracted: http://uurouter.gdl.netease.com/uuplugin/openwrt-aarch64/v10.15.16/uu.tar.gz?key...
⚠️  Old awk method would give different result

... (similar for other architectures)

=========================================
Test Complete
=========================================
```

## Summary

✅ **Fixed** JSON parsing to properly extract download URLs
✅ **Updated** main package Makefile
✅ **Updated** LuCI controller
✅ **Added** download-uu.sh for manual testing
✅ **Added** test-api.sh for validation
✅ **Tested** all 4 architectures successfully

The packages now correctly handle the JSON API response from UU servers.
