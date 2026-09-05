<#
.SYNOPSIS
    取得 ELMAH 單筆錯誤詳情，透過 JSON API 直接回傳。

.PARAMETER Environment
    環境代號。支援: hk-qa, my-qa, hk-prod, my-prod, tw-prod, tw-qa

.PARAMETER Id
    ErrorId (GUID)

.PARAMETER Apps
    (tw-qa 必須) Application 名稱，用於解析直接 ELMAH URL。
    Dashboard 環境可忽略此參數。

.EXAMPLE
    powershell Get-ElmahDetail.ps1 -Environment tw-prod -Id 2556b6e4-65a9-4d3c-9ec2-9a5aa2a45149
    powershell Get-ElmahDetail.ps1 -Environment tw-qa -Apps SCM -Id 47647972-04D9-44DC-A05C-08873ABF309D

.NOTES
    回傳格式：
    {
      "error": {
        "application": "WebApi", "host": "...", "type": "FullNamespacedException",
        "message": "...", "detail": "StackTrace full text...", "time": "2026-04-23T11:46:58Z"
      },
      "serverVariables": { "item": [ { "name": "PATH_INFO", "value": { "string": "..." } }, ... ] },
      "cookies": { "item": [ ... ] }
    }

    serverVariables 解析方式：依 name 查找 value.string，如 HTTP_X_FORWARDED_FOR, HTTP_USER_AGENT 等。
    注意：tw-qa 直接 ELMAH 回傳格式為 flat JSON（無 "error" 包裝），腳本會自動包裝為一致格式。
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [string]$Id,

    [string]$Apps = "SCM"
)

# Dashboard environments
$urlMap = @{
    "hk-qa"   = "http://elmahdashboard.hk.91dev.tw"
    "my-qa"   = "http://elmahdashboard.my.91dev.tw"
    "hk-prod" = "http://elmahdashboard.91app.hk"
    "my-prod" = "http://elmahdashboard.91app.com.my"
    "tw-prod" = "http://elmahdashboard.qa.91dev.tw"
}

# tw-qa 直接 ELMAH URL
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
    $firstApp = ($Apps -split ",")[0].Trim()
    $baseUrl = $twQaAppMap[$firstApp]
    if (-not $baseUrl) {
        $validApps = ($twQaAppMap.Keys | Sort-Object) -join ", "
        Write-Error "Unknown tw-qa app: '$firstApp'. Valid: $validApps"
        exit 1
    }
    # 直接 ELMAH: /json?id={Id}
    $url = "$baseUrl/json?id=$Id"
} else {
    $baseUrl = $urlMap[$envKey]
    if (-not $baseUrl) {
        Write-Error "Unknown environment: '$Environment'. Valid: hk-qa, my-qa, hk-prod, my-prod, tw-prod, tw-qa"
        exit 1
    }
    # Dashboard: /Log/GetJson/{Id}
    $url = "$baseUrl/Log/GetJson/$Id"
}

try {
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
    $content = $response.Content

    if ($isTwQa) {
        # 直接 ELMAH 回傳 flat JSON，包裝為一致格式 {"error": {...}}
        $content = "{`"error`": $content}"
    }

    $content
} catch {
    $status = $_.Exception.Response.StatusCode.Value__
    Write-Error "HTTP $status fetching ELMAH detail for $Id`: $_"
    exit 1
}
