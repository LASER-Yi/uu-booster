# Quick Reference - MD5 Validation & Fallback URL

## Files Updated

### 1. packages/uu-booster/Makefile (Lines 38-103)

**What Changed:**
- Post-install script completely rewritten
- Added MD5 checksum validation
- Added backup URL (url_bak) support
- Added file size validation

**Key Commands:**
```bash
# Extract API fields
EXPECTED_MD5=$(echo "$API_RESPONSE" | sed -n 's/.*"md5":"\([^"]*\)".*/\1/p')
DOWNLOAD_URL=$(echo "$API_RESPONSE" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
DOWNLOAD_URL_BAK=$(echo "$API_RESPONSE" | sed -n 's/.*"url_bak":"\([^"]*\)".*/\1/p')

# Validate download
download_with_validation "$DOWNLOAD_URL" "$EXPECTED_MD5" "$ATTAMPT"

# Fallback to backup URL if primary fails
if [ $? -ne 0 ]; then
  download_with_validation "$DOWNLOAD_URL_BAK" "$EXPECTED_MD5" "$ATTAMPT"
fi
```

---

### 2. packages/luci-app-uu-booster/luasrc/controller/uu-booster.lua (Lines 69-239)

**What Changed:**
- Complete rewrite of `action_update()` function
- Added `download_attempt()` nested function
- Added MD5 validation logic
- Added detailed status reporting

**Key Functions:**
```lua
-- Extract API fields
local expected_md5 = luci.sys.exec("echo '" .. api_response .. "' | sed -n 's/.*\"md5\":\"\\([^\"]*\\)\".*/\\1/p'")
local download_url = luci.sys.exec("echo '" .. api_response .. "' | sed -n 's/.*\"url\":\"\\([^\"]*\\)\".*/\\1/p'")
local download_url_bak = luci.sys.exec("echo '" .. api_response .. "' | sed -n 's/.*\"url_bak\":\"\\([^\"]*\\)\".*/\\1/p'")

-- Download attempt function
local download_attempt = function(url, attempt_name)
  -- Download file
  -- Check file size (reject <1KB)
  -- Calculate MD5 if expected_md5 available
  -- Compare MD5 values
  -- Return success/failure
end

-- Primary then backup logic
local primary_success = download_attempt(download_url, "primary")
if not primary_success then
  local backup_success = download_attempt(download_url_bak, "backup")
end
```

**Status JSON Response:**
```json
{
  "success": true,
  "message": "Update completed successfully",
  "md5_check": "passed",
  "url_used": "primary",
  "calculated_md5": "768cd1bc4ddee165d5aea91f4d03427a",
  "expected_md5": "768cd1bc4ddee165d5aea91f4d03427a"
}
```

---

### 3. packages/luci-app-uu-booster/htdocs/main.htm (Lines 16-198)

**What Changed:**
- Added Download URL display
- Added MD5 Check status
- Added MD5 Details section
- Enhanced JavaScript functions

**New HTML Elements:**
```html
<div class="uu-booster-info">
  <label><%:Download URL:%></label>
  <span id="download-url">-</span>
</div>

<div class="uu-booster-info">
  <label><%:MD5 Check:%></label>
  <span id="md5-check">-</span>
</div>

<div id="md5-details" style="display:none;" class="uu-booster-info">
  <label><%:Expected MD5:%></label>
  <span id="expected-md5">-</span>
</div>

<div id="md5-details" style="display:none;" class="uu-booster-info">
  <label><%:Calculated MD5:%></label>
  <span id="calculated-md5">-</span>
</div>
```

**JavaScript Updates:**
```javascript
// checkVersion() - Now displays download URL
if (data.success) {
  var latestSpan = document.getElementById('latest-version');
  latestSpan.textContent = data.latest_version;
  downloadUrlSpan.textContent = data.download_url.substring(0, 40) + '...';
}

// updateBooster() - Now handles MD5 display
if (data.success) {
  if (data.md5_check === 'passed') {
    var md5DetailsDiv = document.getElementById('md5-details');
    md5DetailsDiv.style.display = 'block';
    document.getElementById('expected-md5').textContent = data.expected_md5 || '-';
    document.getElementById('calculated-md5').textContent = data.calculated_md5 || '-';
  }
}
```

---

### 4. scripts/test-api.sh (Lines 31-66)

**What Changed:**
- Added MD5 field extraction test
- Added backup URL extraction test
- Shows expected MD5 values

**New Test Code:**
```bash
# Extract MD5 and backup URL
EXPECTED_MD5=$(echo "$RESPONSE" | sed -n 's/.*"md5":"\([^"]*\)".*/\1/p')
URL_BAK=$(echo "$RESPONSE" | sed -n 's/.*"url_bak":"\([^"]*\)".*/\1/p')

# Show results
echo "✓ Expected MD5: ${EXPECTED_MD5:0:32}..."

if [ -n "$URL_BAK" ]; then
  echo "✓ Backup URL available: ${URL_BAK:0:60}..."
else
  echo "ℹ️  Backup URL not available"
fi
```

---

## API Response Fields Used

```json
{
  "md5": "768cd1bc4ddee165d5aea91f4d03427a",
  "output": null,
  "signature": null,
  "status": "ok",
  "url": "http://uurouter.gdl.netease.com/...",
  "url_bak": "http://uurouter.gdl04.netease.com/..."
}
```

### Field Purposes

| Field | Purpose | Used In |
|-------|-----------|----------|
| md5 | Expected MD5 checksum | Postinst, LuCI |
| url | Primary download URL | Postinst, LuCI |
| url_bak | Backup/fallback URL | Postinst, LuCI |

---

## MD5 Validation Flow

### Post-install Script (bash)
```
1. Query API → Get JSON response
2. Extract md5, url, url_bak
3. Download from url
4. Calculate MD5 of downloaded file
5. Compare MD5 values
6. If match → Install
7. If mismatch → Try url_bak
8. If url_bak fails → Error
```

### LuCI Controller (lua)
```
1. Query API → Get JSON response
2. Extract md5, url, url_bak
3. Try download from url
4. Validate file size (<1KB = error)
5. Calculate MD5 if available
6. Compare MD5 values
7. If pass → Extract and install
8. If fail → Try url_bak
9. Return detailed status JSON
```

---

## Status Values

### md5_check Field
- `none` - MD5 not available in API response
- `skipped` - MD5 available but validation not performed
- `pending` - MD5 validation in progress
- `passed` - MD5 values match
- `failed` - MD5 values don't match
- `calculated` - MD5 calculated successfully
- `error` - Failed to calculate MD5

### url_used Field
- `primary` - Used primary URL
- `backup` - Used backup URL
- `failed` - Both URLs failed
- `unknown` - URL source not tracked

---

## Error Messages

### File Size Error
```
"Downloaded file too small (X bytes), possibly an error page"
```

### MD5 Mismatch
```
"MD5 checksum mismatch: expected XXX..., got YYY..."
```

### Download Failure
```
"Failed to download from primary URL"
"Failed to download from backup URL"
"Failed to download from both primary and backup URLs"
```

---

## Quick Commands

### Test API
```bash
./scripts/test-api.sh
```

### Download Manually
```bash
./scripts/download-uu.sh openwrt-x86_64
```

### Validate Project
```bash
./scripts/validate.sh
```

### Build Packages
```bash
./scripts/build.sh x86_64
```

---

## Benefits

1. **Security**: MD5 validation ensures file integrity
2. **Reliability**: Fallback URL provides automatic recovery
3. **Transparency**: Shows which URL source was used
4. **User Experience**: Detailed status at each step
5. **Error Prevention**: File size check prevents corrupted files
6. **Debugging**: Clear error messages help troubleshooting

---

## Documentation Files

- **MD5_VALIDATION.md** - Complete implementation guide
- **README.md** - Main project documentation
- **BUILD_GUIDE.md** - Build instructions
- **JSON_FIX.md** - JSON parsing fix (earlier update)
