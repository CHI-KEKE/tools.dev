# ============================================================
# BulkAddTag.ps1
# Bulk-add the same tag to all keys under a specified module
# ============================================================

param(
    [string]$baseUrl     = "https://translation.qa.91dev.tw",
    [string]$ModuleId = "695e3857d23d0c00076b875d", ## 695e3857d23d0c00076b875d
    [string]$Tag      = "",
    [string]$Token    = ""   # Bearer token (without "Bearer " prefix)
)

# ---- Prompt for any missing parameters ----
if (-not $ModuleId) { $ModuleId = Read-Host "ModuleId" }
if (-not $Tag)      { $Tag      = Read-Host "Tag name" }
if (-not $Token)    { $Token    = Read-Host "Bearer Token (without 'Bearer ' prefix)" }

$headers = @{
    "Authorization" = "Bearer $Token"
}

# ---- 1. Fetch all translations in the module ----
Write-Host "`n[1/3] Fetching data for module $ModuleId..." -ForegroundColor Cyan
try {
    $moduleData = Invoke-RestMethod -Uri "$baseUrl/api/v3/modules/$ModuleId" `
                                    -Method GET `
                                    -Headers $headers
} catch {
    Write-Error "Failed to fetch module data: $_"
    exit 1
}

$keys = $moduleData.translations | Select-Object -ExpandProperty key
Write-Host "[2/3] Found $($keys.Count) keys, preparing to add tag: '$Tag'" -ForegroundColor Cyan

if ($keys.Count -eq 0) {
    Write-Warning "No keys found in this module. Exiting."
    exit 0
}

# ---- 2. Confirm before executing ----
Write-Host ""
$confirm = Read-Host "Add tag '$Tag' to all $($keys.Count) keys? (y/N)"
if ($confirm -notin @('y','Y')) {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# ---- 3. Call Add Tag API for each key ----
Write-Host "`n[3/3] Adding tags in bulk..." -ForegroundColor Cyan

$body = @{
    tags = @(
        @{ tag = $Tag }
    )
} | ConvertTo-Json -Depth 3

$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)

Write-Host "[DEBUG] Request body: $body" -ForegroundColor DarkGray
Write-Host "[DEBUG] Body bytes (hex): $(($bodyBytes | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor DarkGray
Write-Host ""

$success = 0
$failed  = @()

foreach ($key in $keys) {
    $url = "$baseUrl/api/v3/modules/$ModuleId/translations/$key/tags/add"
    try {
        Invoke-RestMethod -Uri $url -Method PATCH -Headers $headers -Body $bodyBytes -ContentType "application/json; charset=utf-8" | Out-Null
        Write-Host "  ✓ $key" -ForegroundColor Green
        $success++
    } catch {
        Write-Host "  ✗ $key  ← $_" -ForegroundColor Red
        $failed += $key
    }
}

# ---- 4. Summary ----
Write-Host "`n========== Done ==========" -ForegroundColor Cyan
Write-Host "Success: $success / $($keys.Count)" -ForegroundColor Green
if ($failed.Count -gt 0) {
    Write-Host "Failed ($($failed.Count)):" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
