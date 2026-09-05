# ── 測試用參數，請自行修改 ──────────────────────────────────────────────────
$SlackWebhookUrl = ""   # 或直接貼 URL，如：
# $SlackWebhookUrl = ""

$Market    = "HK"
$DeployEnv = "QA"
$RoundTimeUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$RoundTimeTW  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss+08:00")

$failedSessions = @(
    "LiveSessionId=session-001 ShopId=shop-123 | Error: Connection timeout",
    "LiveSessionId=session-002 ShopId=shop-456 | Error: HTTP 500 Internal Server Error"
)
$failCount = $failedSessions.Count
$totalCount = 5

# ── 組 Slack Block Kit payload ──────────────────────────────────────────────
$failedLines = ($failedSessions | ForEach-Object { "• $_" }) -join "`n"
$slackBody = @{
    blocks = @(
        @{
            type = "header"
            text = @{ type = "plain_text"; text = ":eyes: SyncLiveSessionComment — NMQ Task Creation Failed"; emoji = $true }
        },
        @{
            type   = "section"
            fields = @(
                @{ type = "mrkdwn"; text = "*Market*`n$Market" },
                @{ type = "mrkdwn"; text = "*Environment*`n$DeployEnv" },
                @{ type = "mrkdwn"; text = "*Time (UTC)*`n$RoundTimeUtc" },
                @{ type = "mrkdwn"; text = "*Time (TW)*`n$RoundTimeTW" },
                @{ type = "mrkdwn"; text = "*Result*`n:x: $failCount failed / $totalCount total" }
            )
        },
        @{
            type = "divider"
        },
        @{
            type = "section"
            text = @{ type = "mrkdwn"; text = "*Failed Sessions*`n$failedLines" }
        }
    )
} | ConvertTo-Json -Depth 10

Write-Host "Sending test Slack alert to webhook..."
Write-Host "Payload preview:`n$slackBody`n"

try {
    Invoke-RestMethod -Uri $SlackWebhookUrl -Method POST -Body $slackBody -ContentType 'application/json' -ErrorAction Stop
    Write-Host "SUCCESS: Slack alert sent!"
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)"
}
