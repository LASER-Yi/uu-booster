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

### 2. scripts/test-api.sh (Lines 31-66)

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
 | md5 | Expected MD5 checksum | Postinst |
 | url | Primary download URL | Postinst |
 | url_bak | Backup/fallback URL | Postinst |

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
