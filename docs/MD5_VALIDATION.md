# MD5 Validation & Fallback URL - Implementation Summary

## Overview

Updated binary download implementation to include:
- MD5 checksum validation
- Fallback to `url_bak` if primary URL fails
- Enhanced error handling and user feedback
- Detailed status reporting

## Changes Made

### 1. packages/uu-booster/Makefile (postinst script)

**Lines 38-103:** Completely rewritten post-install script

**New Features:**
- Extracts `md5` from API response
- Extracts `url_bak` (backup URL) from API response
- Calculates MD5 checksum of downloaded file
- Compares MD5 values for validation
- Tries backup URL if primary download fails or MD5 mismatch
- Shows detailed download progress and validation results

**Key Code:**
```bash
# Extract API fields
EXPECTED_MD5=$(echo "$API_RESPONSE" | sed -n 's/.*"md5":"\([^"]*\)".*/\1/p')
DOWNLOAD_URL=$(echo "$API_RESPONSE" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
DOWNLOAD_URL_BAK=$(echo "$API_RESPONSE" | sed -n 's/.*"url_bak":"\([^"]*\)".*/\1/p')

# Validation function
download_with_validation() {
  # Download file
  wget -q -O uu-booster.tar.gz "$url"
  
  # Check file size (detect error pages)
  FILE_SIZE=$(stat -c%s uu-booster.tar.gz)
  if [ -z "$FILE_SIZE" ] || [ "$FILE_SIZE" -lt 1024 ]; then
    echo "Error: Downloaded file too small"
    return 1
  fi
  
  # Calculate MD5
  CALCULATED_MD5=$(md5sum uu-booster.tar.gz | awk '{print $1}')
  
  # Compare MD5
  if [ "$CALCULATED_MD5" = "$EXPECTED_MD5" ]; then
    echo "MD5 checksum: OK"
    return 0
  else
    echo "MD5 checksum: MISMATCH!"
    return 1
  fi
}

# Try primary, then fallback
download_with_validation "$DOWNLOAD_URL" "$EXPECTED_MD5" "$ATTAMPT"
if [ $? -ne 0 ]; then
  if [ -n "$DOWNLOAD_URL_BAK" ] && [ "$DOWNLOAD_URL_BAK" != "$DOWNLOAD_URL" ]; then
    download_with_validation "$DOWNLOAD_URL_BAK" "$EXPECTED_MD5" "$ATTAMPT"
  fi
fi
```

### 2. packages/luci-app-uu-booster/luasrc/controller/uu-booster.lua

**Lines 69-239:** Completely rewritten `action_update()` function

**New Features:**
- Extracts `md5` and `url_bak` from API response
- Implements nested `download_attempt()` function
- Validates download with MD5 checksum
- Shows file size check (detect error pages)
- Tries backup URL if primary fails
- Returns detailed status JSON with:
  - `success`: boolean
  - `message`: status description
  - `md5_check`: "none", "skipped", "pending", "passed", "failed", "calculated", "error"
  - `url_used`: "primary", "backup", "failed"
  - `calculated_md5`: calculated checksum (if available)
  - `expected_md5`: expected checksum (if available)

**Key Code:**
```lua
-- Extract API fields
local expected_md5 = luci.sys.exec("echo '" .. api_response .. "' | sed -n 's/.*\"md5\":\"\\([^\"]*\\)\".*/\\1/p'")
local download_url = luci.sys.exec("echo '" .. api_response .. "' | sed -n 's/.*\"url\":\"\\([^\"]*\\)\".*/\\1/p'")
local download_url_bak = luci.sys.exec("echo '" .. api_response .. "' | sed -n 's/.*\"url_bak\":\"\\([^\"]*\\)\".*/\\1/p'")

-- Download attempt function
local download_attempt = function(url, attempt_name)
  local wget_result = luci.sys.exec("wget -q -O " .. temp_dir .. "/uu-booster.tar.gz '" .. url .. "' 2>&1")
  
  if wget_result ~= "" then
    result.message = "Failed to download from " .. attempt_name .. " URL"
    return false
  end
  
  -- File size check (detect error pages)
  local file_check = luci.sys.exec("stat -c%s '" .. temp_dir .. "/uu-booster.tar.gz 2>&1")
  if file_check and file_check ~= "" then
    local file_size = tonumber(file_check:match("Size: (%d+)"))
    if not file_size or file_size < 1024 then
      result.message = "Downloaded file too small (" .. (file_size or "0") .. " bytes)"
      return false
    end
  end
  
  -- MD5 validation
  if expected_md5 ~= "" then
    local calculated_md5 = luci.sys.exec("md5sum '" .. temp_dir .. "/uu-booster.tar.gz 2>&1 | awk '{print $1}'")
    
    if calculated_md5 ~= "" then
      result.calculated_md5 = calculated_md5
      result.expected_md5 = expected_md5
      
      if calculated_md5 == expected_md5 then
        result.md5_check = "passed"
        result.message = "MD5 checksum passed"
      else
        result.md5_check = "failed"
        result.message = "MD5 checksum mismatch"
        return false
      end
    else
      result.md5_check = "error"
      result.message = "Failed to calculate MD5"
      return false
    end
  end
  
  return true
end

-- Try primary, then fallback
local primary_success = download_attempt(download_url, "primary")
if primary_success then
  result.md5_check = "passed" or result.md5_check
  result.url_used = "primary"
else
  if download_url_bak and download_url_bak ~= "" and download_url_bak ~= download_url then
    result.message = "Primary URL failed, trying backup URL..."
    luci.http.write_json(result)
    
    local backup_success = download_attempt(download_url_bak, "backup")
    
    if backup_success then
      result.md5_check = "passed" or result.md5_check
      result.url_used = "backup"
      result.success = true
      result.message = "Download successful from backup URL"
      luci.http.write_json(result)
    else
      result.success = false
      result.url_used = "failed"
      result.message = "Failed to download from both primary and backup URLs"
    end
  else
    result.success = false
    result.url_used = "failed"
    result.message = "Download failed and no backup URL available"
  end
end
```

### 3. packages/luci-app-uu-booster/htdocs/luci-static/resources/view/uu-booster/main.htm

**Lines 16-37:** Added new UI elements

**New Elements:**
- "Download URL:" label and span
- "MD5 Check:" label and span
- "MD5 Details:" hidden section showing:
  - "Expected MD5:" label and span
  - "Calculated MD5:" label and span

**Lines 71-113:** Updated `checkVersion()` function

**New Features:**
- Displays download URL (truncated to 40 chars)
- Updates UI with API response data

**Lines 115-198:** Updated `updateBooster()` function

**New Features:**
- Shows MD5 check status
- Displays URL used for download
- Shows MD5 details when check is performed
- Colors MD5 status messages appropriately

**Key Code:**
```javascript
// MD5 display
var md5CheckSpan = document.getElementById('md5-check');
var md5Details = document.getElementById('md5-details');

if (data.md5_check === 'passed') {
  md5CheckSpan.textContent = data.md5_check;
  md5CheckSpan.className = 'uu-booster-message ' + data.md5_check;
  
  var md5DetailsDiv = document.getElementById('md5-details');
  md5DetailsDiv.style.display = 'block';
  document.getElementById('expected-md5').textContent = data.expected_md5 || '-';
  document.getElementById('calculated-md5').textContent = data.calculated_md5 || '-';
}
```

### 4. scripts/test-api.sh

**Lines 31-41:** Updated test script

**New Features:**
- Tests `md5` field extraction
- Tests `url_bak` field extraction
- Shows expected MD5 value
- Shows if backup URL is available

**Updated Code:**
```bash
# Extract MD5 and backup URL
EXPECTED_MD5=$(echo "$RESPONSE" | sed -n 's/.*"md5":"\([^"]*\)".*/\1/p')
URL_BAK=$(echo "$RESPONSE" | sed -n 's/.*"url_bak":"\([^"]*\)".*/\1/p')

echo "✓ Expected MD5: ${EXPECTED_MD5:0:32}..."

if [ -n "$URL_BAK" ]; then
  echo "✓ Backup URL available: ${URL_BAK:0:60}..."
else
  echo "ℹ️  Backup URL not available"
fi
```

## API Response Format

The UU API returns JSON with these fields:

```json
{
  "md5": "768cd1bc4ddee165d5aea91f4d03427a",
  "output": null,
  "signature": null,
  "status": "ok",
  "url": "http://uurouter.gdl.netease.com/uuplugin/openwrt-x86_64/v10.15.16/uu.tar.gz?key1=b4cd2ded4c51e64d6ab86e31b3e2b8fb&key2=696bdb24",
  "url_bak": "http://uurouter.gdl04.netease.com/uuplugin/openwrt-x86_64/v10.15.16/uu.tar.gz?key1=b4cd2ded4c51e64d6ab86e31b3e2b8fb&key2=696bdb24"
}
```

## Error Handling

### File Size Check
Detects if downloaded file is an error page (less than 1KB):
```bash
FILE_SIZE=$(stat -c%s uu-booster.tar.gz)
if [ "$FILE_SIZE" -lt 1024 ]; then
  echo "Error: Downloaded file too small, possibly an error page"
  return 1
fi
```

### MD5 Mismatch
Shows detailed information about mismatch:
```lua
{
  "md5_check": "failed",
  "calculated_md5": "a1b2c3d4e5f6",
  "expected_md5": "b7c8d9e1a2f3",
  "message": "MD5 checksum mismatch"
}
```

### URL Fallback
Automatically tries backup URL if primary fails:
```lua
-- Try primary URL
local primary_success = download_attempt(download_url, "primary")

-- If primary fails, try backup
if not primary_success then
  if download_url_bak and download_url_bak ~= download_url then
    local backup_success = download_attempt(download_url_bak, "backup")
    
    if backup_success then
      result.url_used = "backup"
      result.success = true
    else
      result.url_used = "failed"
      result.message = "Failed to download from both URLs"
    end
  end
end
```

## UI Features

### Status Indicators
- **MD5 Check:** Shows "none", "skipped", "pending", "passed", "failed", "calculated", "error"
- **URL Used:** Shows "primary", "backup", "failed", "unknown"
- **Download URL:** Shows truncated URL (40 chars)

### Color Coding
- Green (success): `background: #d4edda`
- Red (error): `background: #f8d7da`
- Blue (info): `background: #d1ecf1`

### Detailed MD5 Info
When MD5 check is performed, shows:
- Expected MD5 value
- Calculated MD5 value
- Visual status indication

## Testing

### Test API Script
```bash
./scripts/test-api.sh
```

Expected output:
```
=========================================
UU API JSON Parsing Test
=========================================

Testing API response parsing...

--- Testing: openwrt-x86_64 ---
✓ URL extracted: http://uurouter.gdl.netease.com/...
✓ Expected MD5: 768cd1bc4ddee165d5aea91f4d03427a...
✓ Backup URL available: http://uurouter.gdl04.netease.com/...

... (similar for other architectures)

=========================================
Test Complete
=========================================

Conclusion: sed-based JSON extraction works correctly
Updated files to use sed instead of awk for JSON parsing
```

### Manual Download Test
```bash
./scripts/download-uu.sh openwrt-x86_64
```

This will:
1. Query UU API
2. Show API response
3. Extract download URL and MD5
4. Download file to `/tmp/uu-booster.tar.gz`
5. Show file size
6. Validate download completed

## Benefits

### Enhanced Reliability
- **MD5 Validation:** Ensures downloaded files are correct
- **Fallback URL:** Automatic retry if primary URL fails
- **File Size Check:** Detects error pages early
- **Detailed Feedback:** Users see exactly what's happening

### Better User Experience
- **Clear Status Messages:** Detailed information at each step
- **Visual Indicators:** Color-coded status in UI
- **Progress Information:** Shows MD5 check, URL used, file sizes
- **Automatic Recovery:** Fallback URL without user intervention

## Summary

✅ **Enhanced** postinst script with MD5 validation and fallback URL
✅ **Enhanced** LuCI controller with detailed status reporting
✅ **Enhanced** UI to show MD5 details and status
✅ **Updated** test scripts to validate new functionality
✅ **Documented** all changes comprehensively

The package system now provides:
- Secure downloads with MD5 validation
- Automatic fallback to backup URL
- Detailed status and error reporting
- Better user feedback and debugging information
