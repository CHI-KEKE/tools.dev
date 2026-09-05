<#
.SYNOPSIS
    查詢 ELMAH 錯誤清單，輸出 JSON。

.PARAMETER Environment
    環境代號。支援: hk-qa, my-qa, hk-prod, my-prod, tw-prod, tw-qa

.PARAMETER Page
    頁碼，預設 1

.PARAMETER Pagesize
    每頁筆數，預設 1000

.PARAMETER Entity
    DataSource: 0=台灣(預設), 1=全聯

.PARAMETER Apps
    Application 名稱，逗號分隔，如 "MobileWebMall,WebApi"

.PARAMETER HostFilter
    過濾特定機器，留空=全部

.PARAMETER Keyword
    Message 關鍵字

.PARAMETER ExceptMessage
    排除含此文字的 Message

.PARAMETER StartTime
    開始時間，格式 "MM/dd/yyyy HH:mm"，預設為 15 分鐘前

.PARAMETER EndTime
    結束時間，格式 "MM/dd/yyyy HH:mm"，預設為現在

.PARAMETER AdditionalColumns
    附加欄位代碼，逗號分隔，預設 "9,10,11,12,13"
    9=QueryString, 10=UserAgent, 11=HttpHost, 12=ClientIP, 13=HttpReferer, 14=ShopId
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,

    [int]$Page = 1,
    [int]$Pagesize = 1000,
    [string]$Entity = "0",
    [string]$Apps = "MobileWebMall,WebApi",
    [string]$HostFilter = "",
    [string]$Keyword = "",
    [string]$ExceptMessage = "",
    [string]$StartTime = "",
    [string]$EndTime = "",
    [string]$AdditionalColumns = "9,10,11,12,13"
)

# Dashboard environments (support App= query param filtering)
$urlMap = @{
    "hk-qa"   = "http://elmahdashboard.hk.91dev.tw"
    "my-qa"   = "http://elmahdashboard.my.91dev.tw"
    "hk-prod" = "http://elmahdashboard.91app.hk"
    "my-prod" = "http://elmahdashboard.91app.com.my"
    "tw-prod" = "http://elmahdashboard.qa.91dev.tw"
}

# tw-qa 沒有 ElmahDashboard，使用各站台直接 ELMAH URL
$twQaAppMap = @{
    "SMS"            = "https://sms.qa.91dev.tw/eadmin/elmah"
    "ScmApi"         = "https://api.qa.91dev.tw/scm/v1/eadmin/elmah"
    "ScmApiV2"       = "https://api.qa.91dev.tw/scm/v2/eadmin/elmah"
    "SCM"            = "https://api.qa.91dev.tw/scm/v2/eadmin/elmah"
    "Mall"           = "http://mall.qa.91dev.tw/eadmin/elmah"
    "MobileWebMall"  = "http://mall.qa.91dev.tw/eadmin/elmah"
    "WebApi"         = "http://mall.qa.91dev.tw/webapi/eadmin/elmah"
}

$envKey = $Environment.ToLower()
$isTwQa = ($envKey -eq "tw-qa")

if ($isTwQa) {
    # tw-qa: resolve URL from app name (use first app if multiple)
    $firstApp = ($Apps -split ",")[0].Trim()
    $baseUrl = $twQaAppMap[$firstApp]
    if (-not $baseUrl) {
        $validApps = ($twQaAppMap.Keys | Sort-Object) -join ", "
        Write-Error "Unknown tw-qa app: '$firstApp'. Valid: $validApps"
        exit 1
    }
} else {
    $baseUrl = $urlMap[$envKey]
    if (-not $baseUrl) {
        Write-Error "Unknown environment: '$Environment'. Valid: hk-qa, my-qa, hk-prod, my-prod, tw-prod, tw-qa"
        exit 1
    }
}

# Default times if not provided
if (-not $StartTime) {
    $StartTime = (Get-Date).AddMinutes(-15).ToString("MM/dd/yyyy HH:mm")
}
if (-not $EndTime) {
    $EndTime = (Get-Date).ToString("MM/dd/yyyy HH:mm")
}

# Helper: strip HTML tags, decode entities, collapse whitespace
$cleanCell = {
    param($raw)
    $t = $raw -replace '<[^>]+>', ' '
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = $t -replace '\s+', ' '
    $t.Trim()
}

$records = [System.Collections.Generic.List[object]]::new()
$total = 0
$pagesizeActual = $Pagesize

if ($isTwQa) {
    # ─── tw-qa: 直接 ELMAH 頁面 (標準 ELMAH UI) ───
    # 格式: ?page=N&size=N，無伺服器端時間/關鍵字過濾
    # 需用戶端過濾時間範圍與關鍵字

    $parsedStart = $null
    $parsedEnd = $null
    if ($StartTime) { $parsedStart = [DateTime]::ParseExact($StartTime, "MM/dd/yyyy HH:mm", $null) }
    if ($EndTime)   { $parsedEnd   = [DateTime]::ParseExact($EndTime,   "MM/dd/yyyy HH:mm", $null) }

    $currentPage = 1
    $maxSize = 100  # 標準 ELMAH 最大每頁筆數
    $reachedEnd = $false

    while (-not $reachedEnd) {
        $url = "$baseUrl/?page=$currentPage&size=$maxSize"
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
            $html = $response.Content
        } catch {
            $status = $_.Exception.Response.StatusCode.Value__
            Write-Error "HTTP $status fetching ELMAH list (tw-qa page $currentPage): $_"
            exit 1
        }

        # Parse total from "Errors 1 to N of total X,XXX"
        if ($total -eq 0 -and $html -match 'of total ([\d,]+)') {
            $total = [int]($Matches[1] -replace ',', '')
        }

        # Parse rows from <table id="ErrorLog">
        $tableMatch = [regex]::Match($html, '(?s)<table id="ErrorLog"[^>]*>(.*?)</table>')
        if (-not $tableMatch.Success) { break }

        $tableHtml = $tableMatch.Groups[1].Value
        $rowMatches = [regex]::Matches($tableHtml, '(?s)<tr class="(?:even|odd)-row">(.*?)</tr>')
        if ($rowMatches.Count -eq 0) { break }

        foreach ($rowMatch in $rowMatches) {
            $rowHtml = $rowMatch.Groups[1].Value
            $cellMatches = [regex]::Matches($rowHtml, '(?s)<td[^>]*>(.*?)</td>')
            if ($cellMatches.Count -lt 7) { continue }

            # Columns: 0=Host, 1=Code, 2=Type, 3=Error(message+detailLink), 4=User, 5=Date, 6=Time

            # Extract errorId from detail link
            $errorRaw = $cellMatches[3].Groups[1].Value
            $errorId = ""
            if ($errorRaw -match 'detail\?id=([a-fA-F0-9\-]{36})') {
                $errorId = $Matches[1]
            }

            # Extract type full name from span title
            $typeRaw = $cellMatches[2].Groups[1].Value
            $typeClean = ""
            if ($typeRaw -match 'title="([^"]+)"') {
                $typeClean = $Matches[1]
            } else {
                $typeClean = & $cleanCell $typeRaw
            }

            # Parse date
            $dateRaw = $cellMatches[5].Groups[1].Value
            $datePart = ""
            if ($dateRaw -match 'title="[^"]*">([^<]+)<') {
                $datePart = $Matches[1].Trim()
            } else {
                $datePart = & $cleanCell $dateRaw
            }

            # Parse time
            $timeRaw = $cellMatches[6].Groups[1].Value
            $timePart = ""
            if ($timeRaw -match 'title="([^"]+)"') {
                $timePart = $Matches[1].Trim()
            } else {
                $timePart = & $cleanCell $timeRaw
            }

            # Client-side time filtering
            if ($parsedStart -or $parsedEnd) {
                $recordDateTime = $null
                try {
                    $dtStr = "$datePart $timePart"
                    $recordDateTime = [DateTime]::Parse($dtStr)
                } catch { }

                if ($recordDateTime) {
                    if ($parsedEnd -and $recordDateTime -gt $parsedEnd) { continue }
                    if ($parsedStart -and $recordDateTime -lt $parsedStart) {
                        # ELMAH 按時間倒序，遇到比 startTime 更早的記錄即可停止
                        $reachedEnd = $true
                        break
                    }
                }
            }

            # Message: strip detail link then clean
            $msgClean = $errorRaw -replace '(?s)<a\s[^>]*href="[^"]*detail[^"]*"[^>]*>.*?</a>', ''
            $msgClean = & $cleanCell $msgClean

            # Client-side keyword filtering
            if ($Keyword -and $msgClean -notmatch [regex]::Escape($Keyword)) { continue }

            $record = [ordered]@{
                no          = $records.Count + 1
                application = & $cleanCell $cellMatches[0].Groups[1].Value
                date        = $datePart
                time        = $timePart
                host        = & $cleanCell $cellMatches[0].Groups[1].Value
                user        = & $cleanCell $cellMatches[4].Groups[1].Value
                type        = $typeClean
                url         = ""
                message     = $msgClean
                codeStack   = ""
                errorId     = $errorId
            }

            $records.Add($record)
        }

        # Stop conditions: reached end of data, or collected enough records
        if ($rowMatches.Count -lt $maxSize) { break }
        if ($records.Count -ge $Pagesize) { break }
        $currentPage++
        if ($currentPage -gt 50) { break }  # safety limit
    }

    $pagesizeActual = $Pagesize

} else {
    # ─── Dashboard 環境 (hk-qa, my-qa, hk-prod, my-prod, tw-prod) ───
    $queryParts = [System.Collections.Generic.List[string]]::new()
    $queryParts.Add("Page=$Page")
    $queryParts.Add("Pagesize=$Pagesize")
    $queryParts.Add("Entity=$Entity")

    foreach ($app in ($Apps -split ",")) {
        $app = $app.Trim()
        if ($app) { $queryParts.Add("App=$app") }
    }

    # Additional columns and column name mapping
    $colNameMap = @{ 9="queryString"; 10="userAgent"; 11="httpHost"; 12="clientIP"; 13="httpReferer"; 14="shopId" }
    $requestedCols = [System.Collections.Generic.List[int]]::new()
    foreach ($col in ($AdditionalColumns -split ",")) {
        $col = $col.Trim()
        if ($col -match '^\d+$') {
            $queryParts.Add("AdditionalColumns=$col")
            $requestedCols.Add([int]$col)
        }
    }

    $queryParts.Add("Host=" + [Uri]::EscapeDataString($HostFilter))
    $queryParts.Add("Keyword=" + [Uri]::EscapeDataString($Keyword))
    $queryParts.Add("ExceptMessage=" + [Uri]::EscapeDataString($ExceptMessage))
    $queryParts.Add("StartTime=" + [Uri]::EscapeDataString($StartTime))
    $queryParts.Add("EndTime=" + [Uri]::EscapeDataString($EndTime))

    $url = "$baseUrl/?" + ($queryParts -join "&")

    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
        $html = $response.Content
    } catch {
        $status = $_.Exception.Response.StatusCode.Value__
        Write-Error "HTTP $status fetching ELMAH list: $_"
        exit 1
    }

    # Parse total count from hidden input
    if ($html -match '<input[^>]+id="count"[^>]+value="(\d+)"' -or
        $html -match '<input[^>]+value="(\d+)"[^>]+id="count"') {
        $total = [int]$Matches[1]
    }

    # Parse actual pagesize from hidden input
    if ($html -match '<input[^>]+id="pagesize"[^>]+value="(\d+)"' -or
        $html -match '<input[^>]+value="(\d+)"[^>]+id="pagesize"') {
        $pagesizeActual = [int]$Matches[1]
    }

    # Extract tbody content of logtable
    $tbodyMatch = [regex]::Match($html, '(?s)<table[^>]*class="table-bordered logtable"[^>]*>.*?<tbody[^>]*>(.*?)</tbody>')
    if ($tbodyMatch.Success) {
        $tbody = $tbodyMatch.Groups[1].Value
        $rowMatches = [regex]::Matches($tbody, '(?s)<tr>(.*?)</tr>')

        $colNameMap = @{ 9="queryString"; 10="userAgent"; 11="httpHost"; 12="clientIP"; 13="httpReferer"; 14="shopId" }

        foreach ($rowMatch in $rowMatches) {
            $rowHtml = $rowMatch.Groups[1].Value
            $cellMatches = [regex]::Matches($rowHtml, '(?s)<td[^>]*>(.*?)</td>')
            if ($cellMatches.Count -lt 9) { continue }

            # Cell 7 (Message): extract errorId before stripping tags
            $msgRaw = $cellMatches[7].Groups[1].Value
            $errorId = ""
            if ($msgRaw -match 'href="/Log/(?:0/)?Details/([a-fA-F0-9\-]{36})"') {
                $errorId = $Matches[1]
            }
            # Remove the Details anchor entirely, then strip
            $msgClean = $msgRaw -replace '(?s)<a\s[^>]*href="[^"]*(?:Details)[^"]*"[^>]*>.*?</a>', ''
            $msgClean = & $cleanCell $msgClean

            # Cell 5 (Type): strip <p> tags
            $typeClean = & $cleanCell $cellMatches[5].Groups[1].Value

            # Parse date and time from DateTime cell (format "MM/dd HH:mm:ss.fff")
            $dtRaw = & $cleanCell $cellMatches[2].Groups[1].Value
            $datePart = ""; $timePart = ""
            if ($dtRaw -match '^(\d{2}/\d{2})\s+(\d{2}:\d{2}:\d{2})') {
                $datePart = $Matches[1]; $timePart = $Matches[2]
            }

            $noRaw = & $cleanCell $cellMatches[0].Groups[1].Value

            $record = [ordered]@{
                no          = if ($noRaw -match '^\d+$') { [int]$noRaw } else { 0 }
                application = & $cleanCell $cellMatches[1].Groups[1].Value
                date        = $datePart
                time        = $timePart
                host        = & $cleanCell $cellMatches[3].Groups[1].Value
                user        = & $cleanCell $cellMatches[4].Groups[1].Value
                type        = $typeClean
                url         = & $cleanCell $cellMatches[6].Groups[1].Value
                message     = $msgClean
                codeStack   = & $cleanCell $cellMatches[8].Groups[1].Value
                errorId     = $errorId
            }

            # Map additional columns by request order
            for ($i = 0; $i -lt $requestedCols.Count; $i++) {
                $cellIdx = 9 + $i
                if ($cellIdx -lt $cellMatches.Count) {
                    $colCode = $requestedCols[$i]
                    $colName = $colNameMap[$colCode]
                    if ($colName) {
                        $record[$colName] = & $cleanCell $cellMatches[$cellIdx].Groups[1].Value
                    }
                }
            }

            $records.Add($record)
        }
    }
}

$output = [ordered]@{
    total     = $total
    truncated = ($records.Count -ge $pagesizeActual -and $total -gt $pagesizeActual)
    records   = @($records)
}

$output | ConvertTo-Json -Depth 5 -Compress:$false
