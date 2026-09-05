---
name: common-grafana-loki-query
description: >
  ALWAYS use this skill when the user provides a Grafana dashboard URL or wants to
  read/query any Grafana dashboard content, including Loki logs, panel data, or
  dashboard configuration. This skill has its own Bearer token and bypasses MCP
  permission limitations (MCP lacks dashboards:read permission).
  Trigger on: any Grafana dashboard URL (monitoring-dashboard.91app.io/d/...),
  or when user says "查 Loki log", "讀取 Grafana dashboard", "查詢 log", "查 dashboard",
  "Loki 查詢", "看 Grafana", "查監控", or provides any Grafana monitoring URL.
  Also supports EDITING dashboard panel expressions via REST API when user reports
  dashboard filter bugs or asks to fix LogQL queries.
  Do NOT attempt Grafana MCP dashboard tools first — always use this skill directly.
---

# Grafana Loki Query via REST API

Query Loki logs directly through Grafana's `/api/ds/query` endpoint. Works with **any** Grafana Loki dashboard.  
Also supports **editing dashboard expressions** via REST API.

---

## When to Use

- **ANY time user provides a Grafana dashboard URL** — always use this skill first, do NOT try MCP dashboard tools
- User wants to read, query, or view any Grafana dashboard content (logs, panels, config)
- User provides a Grafana monitoring URL (e.g., `monitoring-dashboard.91app.io/d/...`)
- Need to query Loki logs with specific filters from any dashboard
- **User reports a dashboard filter bug** — use `-SaveDashboard` mode to fix expressions
- **User wants to add/modify dashboard panels** — use `-InspectDashboard` to discover panel IDs first, then manipulate JSON directly
- Grafana MCP tools return 403 (MCP service account lacks `dashboards:read` permission)

> ⚠️ **Important:** The Grafana MCP service account does NOT have `dashboards:read` permission.
> This skill uses a dedicated Bearer token that has full dashboard access. Always prefer this skill over MCP for dashboard operations.

## Quick Reference

| Item | Value |
|------|-------|
| Script | `Query-GrafanaLoki.ps1` in this skill directory |
| Query Endpoint | `POST https://<grafana-host>/api/ds/query` |
| Save Endpoint | `POST https://<grafana-host>/api/dashboards/db` |
| Auth Header | `Authorization: Bearer <token>` |
| Org Header | `X-Grafana-Org-Id: <orgId>` (parsed from URL) |
| Time range | `from` / `to` from URL, or `"now-1h"` / `"now"` |

| Mode | Switch | Purpose |
|------|--------|---------|
| Query (default) | *(none)* | Execute Loki log queries from a dashboard |
| Edit | `-SaveDashboard` | Find & replace panel expressions and save |
| Inspect | `-InspectDashboard` | List all panels: ID / Type / Title / Queries / Transformations |

---

## Usage — Query Mode (Default)

Run the script with a full dashboard URL and Bearer token:

```powershell
# Locate the skill relative to the current repo root (works in any repo)
$skillDir = Join-Path (git -C $PWD rev-parse --show-toplevel) ".github\skills\common-grafana-loki-query"

# Auto-discover LogQL from dashboard panels
& "$skillDir\Query-GrafanaLoki.ps1" `
    -DashboardUrl "<full-grafana-dashboard-url-with-query-params>" `
    -Token "<bearer-token>"

# Or provide a custom LogQL expression
& "$skillDir\Query-GrafanaLoki.ps1" `
    -DashboardUrl "<url>" `
    -Token "<token>" `
    -Expr '{service="my-service"}' `
    -MaxLines 100
```

### Parameters (Query Mode)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-DashboardUrl` | Yes | Full Grafana dashboard URL with all `var-*` query params |
| `-Token` | Yes | Grafana Bearer token (`glsa_...`) |
| `-Expr` | No | Custom LogQL. If omitted, auto-discovered from dashboard |
| `-MaxLines` | No | Max log lines (default: 50) |
| `-PanelIndex` | No | Which panel's query to use, 0-based (default: 0) |

---

## Usage — Dashboard Edit Mode

Fix dashboard panel expressions without opening the Grafana UI:

```powershell
# Locate the skill relative to the current repo root (works in any repo)
$skillDir = Join-Path (git -C $PWD rev-parse --show-toplevel) ".github\skills\common-grafana-loki-query"

& "$skillDir\Query-GrafanaLoki.ps1" `
    -DashboardUrl "<dashboard-url>" `
    -Token "<token>" `
    -SaveDashboard `
    -SearchPattern '.*${RequestPath}.*' `
    -ReplacePattern '(.*${RequestPath}.*)?'  `
    -CommitMessage "Fix RequestPath filter for services without _props_RequestPath field"
```

### Parameters (Edit Mode)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-DashboardUrl` | Yes | Dashboard URL (only orgId and UID are used) |
| `-Token` | Yes | Grafana Bearer token with **Edit** permission |
| `-SaveDashboard` | Yes | Switch to enable edit mode |
| `-SearchPattern` | Yes | Literal string to find in dashboard JSON |
| `-ReplacePattern` | Yes | Replacement string |
| `-CommitMessage` | No | Save message (auto-generated if omitted) |

### Permission Requirements for Edit Mode

The service account needs **BOTH**:
1. **Dashboard-level**: Edit permission on the specific dashboard
2. **Folder-level**: Edit (or at minimum View) permission on the **parent folder**

> ⚠️ Dashboard-level Edit alone is NOT sufficient for API saves!
> Grafana's `POST /api/dashboards/db` validates folder access even when updating an existing dashboard.

To grant permissions:
1. Go to **Dashboards → [Folder Name] → Settings → Permissions**
2. Add the service account (e.g., `sa-2-csd-readonly`) with **Edit** role

---

## Usage — Dashboard Inspection Mode

Quickly list every panel in a dashboard (IDs, types, titles, query counts, transformation counts).  
**Always run this before manually adding or modifying panels** so you know which IDs are in use.

```powershell
# Locate the skill relative to the current repo root (works in any repo)
$skillDir = Join-Path (git -C $PWD rev-parse --show-toplevel) ".github\skills\common-grafana-loki-query"

& "$skillDir\Query-GrafanaLoki.ps1" `
    -DashboardUrl "<dashboard-url>" `
    -Token "<token>" `
    -InspectDashboard
```

Sample output:

```
=== Dashboard Inspection Mode ===
  Title:   [ShoppingCart] Loki Log Copy
  UID:     49d69ff8-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Version: 22
  Folder:  Logistics-Center (d1415e7d-...)
  canSave: True

=== Panels (14 total) ===
 ID  Type        Title                           Queries  Transformations  TransformNames
---  ----------  ------------------------------  -------  ---------------  ------------------------------------------
144  row         Logs                            0        0
99901 timeseries Log Volume                      1        0
137  table       WebAPI Log Filter (Prod)        1        0
...
210  row         Log Details                     0        0
211  piechart    Log Level Distribution          1        3                partitionByValues, renameByRegex, renameByRegex
212  piechart    RequestPath Distribution        1        3                partitionByValues, renameByRegex, renameByRegex
```

> Panels inside **collapsed rows** are also shown (the script recurses into nested `panels` arrays).

---

## Loki Pie Charts — Correct Setup for `sum by (label)` Queries

### The Problem

When a Loki `instant` query uses `sum by (extracted_label)`, the result is a **wide-format table**, not labelled series.  
`legendFormat = "{{_lvl}}"` does **NOT** work for JSON-extracted labels (it only works for stream labels defined in `{service=~"..."}`).  
Empty legendFormat → all series collapse to a single entry named **`"Value #A"`** → pie chart shows one 100% slice.

### Root Cause

| Label type | After `| json` | `legendFormat = "{{name}}"` works? |
|-----------|----------------|-------------------------------------|
| Stream label (`service`, `container`) | Already available | ✅ Yes |
| JSON-extracted (`_lvl`, `_props_RequestPath`) | Extracted in pipeline | ❌ No — evaluates to empty |

### Correct Panel JSON Pattern

Always add **3 transformations** to a pie chart whose query is `sum by (extracted_label) (...)`:

```json
{
  "type": "piechart",
  "targets": [{
    "expr": "sum by (_lvl) (...base_query...)",
    "instant": true,
    "legendFormat": "",
    "queryType": "instant"
  }],
  "transformations": [
    {
      "id": "partitionByValues",
      "options": { "fields": ["_lvl"] }
    },
    {
      "id": "renameByRegex",
      "options": {
        "regex": "^Value #A (.+)$",
        "renamePattern": "$1"
      }
    },
    {
      "id": "renameByRegex",
      "options": {
        "regex": "^Value #A$",
        "renamePattern": "(empty)"
      }
    }
  ]
}
```

### Why 3 Transformations?

| # | Transformation | What it does |
|---|---------------|-------------|
| 1 | `partitionByValues` by `_lvl` | Splits wide table into one data frame per label value. Grafana names each frame `"Value #A <value>"` (e.g. `"Value #A Information"`) |
| 2 | `renameByRegex`: `^Value #A (.+)$` → `$1` | Strips the prefix: `"Value #A Information"` → `"Information"` |
| 3 | `renameByRegex`: `^Value #A$` → `(empty)` | Handles logs with an **empty** extracted field — those produce a frame named exactly `"Value #A"` with no suffix; the previous regex `.+` won't match |

> The `fields` value in `partitionByValues` must match the **column name in the LogQL result**, which equals the label name in `sum by (...)`.  
> e.g. `sum by (_props_RequestPath)` → `"fields": ["_props_RequestPath"]`

### PowerShell: Apply This Pattern to a Panel

```powershell
# $panel = the piechart hashtable retrieved from $dashboard.panels
$labelField = "_lvl"   # adjust per pie chart
$panel.transformations = @(
    [ordered]@{
        id      = "partitionByValues"
        options = [ordered]@{ fields = @($labelField) }
    },
    [ordered]@{
        id      = "renameByRegex"
        options = [ordered]@{ regex = "^Value #A (.+)$"; renamePattern = '$1' }
    },
    [ordered]@{
        id      = "renameByRegex"
        options = [ordered]@{ regex = "^Value #A$"; renamePattern = "(empty)" }
    }
)
```

---

## Aggregation Granularity: Pie Chart vs Summary Table

A dashboard often has **both** a pie chart and a breakdown table for the same log data.  
Their numbers look different for the same dimension — **this is expected and correct**.

| Panel | LogQL | What it shows |
|-------|-------|---------------|
| Pie chart | `sum by (_props_RequestPath) (...)` | Total per path, **all levels collapsed** |
| Summary table | `sum by (_lvl, _props_RequestPath) (...)` | Per *(level × path)* combination |

**Example:** `/api/carts/create`
- Pie chart → **203** (Information: 199 + Warning: 4 = 203 ✓)
- Table row 1 → `Information | /api/carts/create | 199`
- Table row 2 → `Warning | /api/carts/create | 4`

To verify consistency: sum all table rows for the same path across levels — they must equal the pie slice value.

---

## PowerShell Patterns for Dashboard JSON Manipulation

### Complete Fetch → Modify → Save Pattern

```powershell
# Extract these values from the Grafana dashboard URL
$grafanaHost  = "<your-grafana-host>"        # e.g. https://monitoring-dashboard.91app.io
$dashboardUid = "<dashboard-uid>"            # from URL: /d/<uid>/...
$Token        = "<bearer-token>"             # glsa_...
$orgId        = "<org-id>"                   # from URL: ?orgId=...

$headers = @{
    "Authorization"    = "Bearer $Token"
    "X-Grafana-Org-Id" = $orgId
    "Content-Type"     = "application/json"
}

# 1. FETCH
$raw  = Invoke-WebRequest -Uri "$grafanaHost/api/dashboards/uid/$dashboardUid" -Headers $headers
$obj  = $raw.Content | ConvertFrom-Json -Depth 50 -AsHashtable   # -Depth 50 is critical
$db   = $obj.dashboard
$folderUid = $obj.meta.folderUid   # REQUIRED — must be included in save payload

# 2. MODIFY (examples below)
# ...

# 3. SAVE — remove numeric 'id' (keep 'uid'), include folderUid
$db.Remove("id") | Out-Null
$payload = [ordered]@{
    dashboard = $db
    folderUid = $folderUid
    message   = "Describe your change"
    overwrite = $true
} | ConvertTo-Json -Depth 50 -Compress

$resp = Invoke-WebRequest `
    -Uri "$grafanaHost/api/dashboards/db" `
    -Headers $headers `
    -Method Post `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($payload)) `   # UTF-8 required for CJK characters
    -ContentType "application/json; charset=utf-8"

Write-Host "Saved as version $(($resp.Content | ConvertFrom-Json).version)"
```

### Common Modification Patterns

```powershell
# Find panels by ID
$panel = $db.panels | Where-Object { $_.id -eq 212 }

# Find panels by title (partial match)
$panel = $db.panels | Where-Object { $_.title -like "*RequestPath*" }

# Add a transformation to specific panels
foreach ($p in $db.panels) {
    if ($p.id -in 211, 212, 213, 214) {
        $p.transformations += [ordered]@{
            id      = "renameByRegex"
            options = [ordered]@{ regex = "^Value #A$"; renamePattern = "(empty)" }
        }
    }
}

# Add a new row panel
$db.panels += [ordered]@{
    id        = 210
    type      = "row"
    title     = "Log Details"
    collapsed = $false
    gridPos   = [ordered]@{ h = 1; w = 24; x = 0; y = 20 }
    panels    = @()
}
```

### PowerShell Gotchas

| Issue | Cause | Fix |
|-------|-------|-----|
| `$db.panels \| Where-Object { $_.id -eq 211 }` returns nothing | `id` from JSON is Int32; comparison type mismatch | Use `-eq 211` (PowerShell coerces) **or** string compare: `"$($_.id)" -eq "211"` |
| Hashtable key lookup `$map[211]` fails | Hashtable built with `@{ 211 = ... }` uses Int32 keys; `.id` may be different type | Always use string keys: `@{ "211" = ... }` |
| CJK characters corrupted after save | Default POST body encoding | Use `[System.Text.Encoding]::UTF8.GetBytes($payload)` |
| `ConvertFrom-Json` loses nested arrays / objects | Default depth is 2 | Always use `-Depth 50 -AsHashtable` |
| Save returns 403 "Access denied" | Token lacks folder-level Edit | SA must have Edit on **parent folder**, not just the dashboard |
| Save returns "Dashboard id mismatch" | Old numeric `id` in payload conflicts | Call `$db.Remove("id")` before building save payload |
| `folderUid` not in payload → dashboard moved to General | `folderUid` omitted | Always read `$obj.meta.folderUid` and include it |

---

## How It Works

### Query Mode (4 steps)

1. **Parse URL** — extracts `orgId`, `var-Loki` (datasource UID), `var-*` (filters), `from`/`to`
2. **Discover LogQL** — fetches dashboard JSON, finds panel `expr`, substitutes `$Variable` placeholders with URL params. Empty vars and `$__all` → filter line removed
3. **Query Loki** — POST to `/api/ds/query` with resolved expression
4. **Parse & Display** — outputs summary (level counts, top sources) + formatted log table

### Edit Mode (3 steps)

1. **Parse URL** — extracts `orgId` and dashboard UID
2. **Fetch & Replace** — GET dashboard JSON, apply literal string replacement on all occurrences
3. **Save** — POST updated JSON to `/api/dashboards/db` with `overwrite: true`

### Inspect Mode (2 steps)

1. **Parse URL** — extracts `orgId` and dashboard UID
2. **Fetch & Display** — GET dashboard JSON, flatten all panels (including those nested inside collapsed rows), output table with ID / Type / Title / Queries / Transformations

---

## LogQL Variable Substitution Rules

The script auto-substitutes `var-*` URL params into the LogQL template:

| Pattern in LogQL | Substitution Rule |
|------------------|-------------------|
| `$VarName` or `${VarName}` | Replaced with URL param `var-VarName` value |
| Value = `$__all` | Filter line removed (matches everything) |
| Value = empty string | Filter line `\|~ \`\`` removed |

### Optional Group Fix (Automatic)

When a `|~` line filter has a non-empty value AND a corresponding label filter (`=~`) uses the same value, the script automatically wraps the label filter regex in an optional group:

```
Before: | _props_RequestPath =~ `.*value.*`
After:  | _props_RequestPath =~ `(.*value.*)?`
```

**Why?** Some services (e.g., `hk-qa-bfo`) log fields in a different format (e.g., `request-path` → `request_path` after `| json`), so `_props_RequestPath` is empty. Without the optional group:
- `=~ \`.*value.*\`` does NOT match empty string → query returns 0 results
- `=~ \`(.*value.*)?`` matches empty string (0 repetitions) → works correctly

This preserves filtering for services that DO have the field while allowing services without it to still return results (filtered by the `|~` line filter instead).

---

## Supported Log Formats

The script auto-detects and parses two common 91APP log formats:

| Field | Serilog Compact | Standard Serilog |
|-------|----------------|-----------------|
| Message | `_msg` | `message`, `msg` |
| Level | `_lvl` | `log-level`, `level`, `Level` |
| Source | `_srctx` | `source-context`, `SourceContext` |
| Trace ID | `_tid` | `trace-id`, `TraceId`, `request-id` |

### Known Service Format Differences

| Service Pattern | Format | JSON Field Style |
|----------------|--------|-----------------|
| Most services (TW, MY) | Serilog Compact | `_msg`, `_lvl`, `_props_RequestPath` |
| `hk-qa-bfo`, HK services | Standard Serilog | `message`, `log-level`, `request-path` |

> After `| json`, kebab-case fields become underscore: `request-path` → `request_path`

---

## Response Structure

`POST /api/ds/query` returns:

```
results.A.frames[0].data.values
  [0] → labels (objects: container, service, ...)
  [1] → timestamps (epoch ms)
  [2] → log lines (JSON strings)
  [3] → tsNs (nanosecond timestamps)
  [4] → id (log entry IDs)
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing `X-Grafana-Org-Id` header | Script auto-extracts from URL `orgId` param |
| `ConvertFrom-Json` case-sensitivity error | Script uses `System.Text.Json.JsonDocument` |
| Not URL-decoding variable values | Script uses `HttpUtility.ParseQueryString` |
| Wrong panel selected | Use `-PanelIndex` to pick a different panel |
| Dashboard save returns 403 "Access denied" | SA needs Edit on **parent folder**, not just dashboard |
| RequestPath filter returns 0 results | Field name differs between services; script auto-applies optional group fix |
| Logs show "Unknown" level | Service uses non-compact format; script now supports both |
| Pie chart shows a single 100% "Value #A" slice | `legendFormat = "{{extracted_label}}"` doesn't work for JSON-extracted labels → see **Loki Pie Charts** section; add `partitionByValues` + 2× `renameByRegex` transformations |
| Pie chart legend still shows "Value #A " prefix | `renameByRegex` pattern `^Value #A (.+)$` only handles non-empty suffix; also add pattern `^Value #A$` → `(empty)` for empty extracted fields |
| `$db.panels \| Where-Object { $_.id -eq 211 }` returns nothing | Type mismatch (Int32 vs other); use string compare `"$($_.id)" -eq "211"` or run `$p.id -in @(211,212)` |
| Hashtable key lookup `$map[211]` fails | Int32 vs String key type; always use string keys: `@{ "211" = ... }` |
| CJK characters corrupted in saved dashboard | Default encoding; use `[System.Text.Encoding]::UTF8.GetBytes($payload)` |
| Dashboard moved to "General" folder after save | `folderUid` omitted from payload; always read `$obj.meta.folderUid` |
| "Dashboard id mismatch" error on save | Stale `id` field conflicts; call `$db.Remove("id")` before save |
| Pie chart count looks wrong compared to table | Expected — different aggregation (`sum by (A)` vs `sum by (A,B)`); verify by summing all table rows for same path |

---

## 91APP Monitoring Defaults

| Setting | Value |
|---------|-------|
| Grafana Host | `monitoring-dashboard.91app.io` |
| Default Org ID | `2` |
| Token (env var) | Set `$env:GRAFANA_TOKEN` before calling the script, **or** pass `-Token` explicitly |
| Service Account | `sa-2-csd-readonly` (CSD-ReadOnly) |

> The actual token value is stored in team secrets and must not be committed to source code.
