# BulkAddTag.ps1 — Chinese Encoding Debug Notes

## Problem

When running `BulkAddTag.ps1` with a Chinese tag name (e.g. `EPIC_直播活動`),
the tag was garbled in the console output and all API calls returned `400 Bad Request`:

```
Add tag 'EPIC_?湔瘣餃?' to all 91 keys? (y/N): y
  ✗ status_has_changed  ← The remote server returned an error: (400) Bad Request.
```

---

## Root Cause Analysis

### Issue 1 — Script-level: Hardcoded Chinese default value

**PowerShell 5.x reads `.ps1` files using the system's default ANSI encoding**
(Windows-1252 on most Windows machines), **not UTF-8**, unless the file is saved
with a UTF-8 BOM.

Since `BulkAddTag.ps1` was created as UTF-8 without BOM, the hardcoded default:

```powershell
[string]$Tag = "EPIC_直播活動"
```

was misread at load time, producing garbled bytes before the script even ran.

**Fix:** Remove all Chinese characters from the script source. Pass the tag via
`-Tag` parameter at invocation time — PowerShell receives CLI arguments as
Unicode strings, bypassing the file-encoding issue entirely.

---

### Issue 2 — HTTP level: `Invoke-RestMethod` body encoding

Even after fixing Issue 1, the original code used:

```powershell
$body = @{ tags = @(@{ tag = $Tag }) } | ConvertTo-Json -Depth 3
Invoke-RestMethod ... -Body $body -ContentType "application/json"
```

`Invoke-RestMethod` in PowerShell 5.x serializes the `-Body` string using the
**system default encoding** (not UTF-8). The server receives mojibake bytes,
rejects the payload, and returns `400 Bad Request`.

**Fix:** Explicitly convert the JSON string to a UTF-8 byte array before sending:

```powershell
$body      = @{ tags = @(@{ tag = $Tag }) } | ConvertTo-Json -Depth 3
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
Invoke-RestMethod ... -Body $bodyBytes -ContentType "application/json; charset=utf-8"
```

This guarantees the wire bytes are always valid UTF-8 regardless of system locale.

---

## Debugging Steps Taken

### Step 1 — Identify where garbling happens

Added debug output immediately after building the body, before the loop:

```powershell
Write-Host "[DEBUG] Request body: $body" -ForegroundColor DarkGray
Write-Host "[DEBUG] Body bytes (hex): $(($bodyBytes | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor DarkGray
```

**How to read the hex output:**

The UTF-8 encoding of `直播活動` is:

| Char | UTF-8 bytes     |
|------|-----------------|
| 直   | `E7 9B B4`      |
| 播   | `E6 92 AD`      |
| 活   | `E6 B4 BB`      |
| 動   | `E5 8B 95`      |

If the hex output matches the table above, the body is correctly encoded.
If you see bytes like `3F` (ASCII `?`) or Windows-1252 sequences, the encoding is wrong.

### Step 2 — Verify `$Tag` value at runtime

```powershell
Write-Host "[DEBUG] Tag value: $Tag"
Write-Host "[DEBUG] Tag bytes: $([System.Text.Encoding]::UTF8.GetBytes($Tag) | ForEach-Object { $_.ToString('X2') })"
```

This confirms whether the variable itself was garbled before JSON serialization.

---

## Final Fix Summary

| # | Location | Problem | Fix |
|---|----------|---------|-----|
| 1 | `.ps1` source file | Chinese default value garbled on load (no UTF-8 BOM) | Remove Chinese from source; pass via `-Tag` parameter |
| 2 | `Invoke-RestMethod` | Body string encoded with system ANSI, not UTF-8 | Convert to `UTF8.GetBytes()` before sending |

---

## Correct Usage

```powershell
# Always pass the tag as a parameter, never rely on a hardcoded default
.\BulkAddTag.ps1 -Tag "EPIC_直播活動" -Token "eyJhbG..."

# Targeting a different environment
.\BulkAddTag.ps1 -baseUrl "https://translation.pp.91dev.tw" `
                 -ModuleId "6970a73a4e14620007e8b6c0" `
                 -Tag "EPIC_直播活動" `
                 -Token "eyJhbG..."
```

---

## Key Takeaway

> In PowerShell 5.x on Windows, **never hardcode non-ASCII characters in `.ps1`
> source files** unless the file is explicitly saved as **UTF-8 with BOM**.
> Always pass such values as runtime parameters, and always encode HTTP request
> bodies as explicit UTF-8 byte arrays.
