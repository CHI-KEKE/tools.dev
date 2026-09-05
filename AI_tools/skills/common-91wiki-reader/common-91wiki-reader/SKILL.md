---
name: common-91wiki-reader
description: 透過已登入的 Chrome（直接 CDP WebSocket，不用 playwright-cli）存取 wiki.91app.com，支援關鍵字搜尋與頁面內容讀取。當使用者說「查 wiki」、「找 wiki」、「wiki 搜尋」、「91wiki」、「查 confluence」、「wiki 上怎麼說」、「wiki 有沒有」、「搜尋 wiki」、「wiki 找找看」，立即使用此 skill。
allowed-tools: Bash(powershell:*)
---

# 91Wiki 閱讀工具

透過已登入的 Chrome（直接 CDP WebSocket）存取 wiki.91app.com。  
`web_fetch` 無法存取 91wiki（需登入），必須使用此方式。

## ⚠️ 重要：不要用 playwright-cli

| 工具 | 問題 |
|------|------|
| `playwright-cli open` | 啟動新的 headless Chrome，沒有登入 Cookie，且觸發「Chrome 目前受到自動測試軟體控制」banner |
| `playwright-cli attach --cdp=chrome` | 會卡住或注入 automation flag，同樣觸發 banner |
| `playwright-cli tab-list` | 只看得到 playwright-cli 管理的 tab，看不到使用者的 tab |

**正確做法：用 PowerShell WebSocket 直接走 CDP，連進使用者已開啟且已登入的 Chrome，不觸發任何 popup。**

## ⚠️ 為何會反覆跳出「允許遠端偵錯嗎？」

每次 `Invoke-WikiCDP` 建立新 WebSocket 連線後立刻關閉，Chrome 將每次新連線視為新的外部客戶端，因此反覆跳 popup。

**解法：建立一次連線，整個 session 保持不關，之後每次呼叫重用同一個 WebSocket。**

## 核心 Helper 函數（持久連線版）

**每次 PowerShell session 貼入一次**，之後 `Connect-WikiCDP` 只需執行一次（popup 只出現一次），後續 `Invoke-WikiCDP` 不再跳 popup：

```powershell
Add-Type -AssemblyName System.Net.WebSockets.Client

$global:_WikiWS = $null
$global:_WikiSID = $null
$global:_WikiMsgId = 10

function _Send-WikiWS($id, $method, $params=@{}, $sid=$null) {
    $msg = [ordered]@{id=$id; method=$method; params=$params}
    if ($sid) { $msg["sessionId"] = $sid }
    $b = [System.Text.Encoding]::UTF8.GetBytes(($msg | ConvertTo-Json -Compress -Depth 10))
    $global:_WikiWS.SendAsync([ArraySegment[byte]]$b, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).Wait()
}

function _Read-WikiWS {
    $ms = New-Object System.IO.MemoryStream; $buf = New-Object byte[] 524288
    do { $r = $global:_WikiWS.ReceiveAsync([ArraySegment[byte]]$buf, [System.Threading.CancellationToken]::None).Result; $ms.Write($buf, 0, $r.Count) } while (-not $r.EndOfMessage)
    return [System.Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
}

function Connect-WikiCDP {
    # 找 wiki tab 並附加，整個 session 只需呼叫一次
    $wsPath = (Get-Content "$env:LOCALAPPDATA\Google\Chrome\User Data\DevToolsActivePort")[1].Trim()
    $global:_WikiWS = New-Object System.Net.WebSockets.ClientWebSocket
    $global:_WikiWS.ConnectAsync([Uri]"ws://localhost:9222$wsPath", [System.Threading.CancellationToken]::None).Wait()

    _Send-WikiWS 1 "Target.getTargets"
    $wikiId = ((_Read-WikiWS).result.targetInfos | Where-Object { $_.url -like "*wiki.91app.com*" -and $_.type -eq "page" } | Select-Object -First 1).targetId
    if (-not $wikiId) { throw "找不到 wiki tab，請先在 Chrome 開啟 wiki.91app.com" }

    _Send-WikiWS 2 "Target.attachToTarget" @{targetId=$wikiId; flatten=$true}
    $resp = _Read-WikiWS; while (-not $resp.result) { $resp = _Read-WikiWS }
    $global:_WikiSID = $resp.result.sessionId
    $global:_WikiMsgId = 10
    Write-Host "✅ Wiki CDP 連線成功，後續查詢不再跳 popup"
}

function Invoke-WikiCDP {
    param([string]$JS)
    # 自動重連（若 WebSocket 已關閉）
    if (-not $global:_WikiWS -or $global:_WikiWS.State -ne 'Open') { Connect-WikiCDP }
    $id = ++$global:_WikiMsgId
    _Send-WikiWS $id "Runtime.evaluate" @{expression=$JS; awaitPromise=$true; returnByValue=$true} $global:_WikiSID
    do { $resp = _Read-WikiWS } while ($resp.id -ne $id)
    return $resp.result.result.value
}

function Disconnect-WikiCDP {
    if ($global:_WikiWS -and $global:_WikiWS.State -eq 'Open') {
        $global:_WikiWS.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", [System.Threading.CancellationToken]::None).Wait()
    }
    $global:_WikiWS = $null; $global:_WikiSID = $null
    Write-Host "Wiki CDP 已中斷"
}
```

## 方式一：關鍵字搜尋

```powershell
# 定義 Helper 後直接呼叫（關鍵字可中英文）
$results = Invoke-WikiCDP "fetch('/rest/api/content/search?cql=text+~+%22未轉單%22&limit=10',{credentials:'include'}).then(r=>r.json()).then(d=>JSON.stringify(d.results.map(p=>({id:p.id,title:p.title,url:p._links.webui}))))"
$results | ConvertFrom-Json | Format-Table id, title -AutoSize
```

## 方式二：讀取頁面內容（已知 pageId）

```powershell
# REST API 取得渲染純文字（最快，不需要 goto）
$content = Invoke-WikiCDP "fetch('/rest/api/content/54716193?expand=body.view',{credentials:'include'}).then(r=>r.json()).then(d=>{const t=document.createElement('div');t.innerHTML=d.body.view.value;return t.innerText})"
Write-Host $content
```

> 注意：`body.storage` 是 Confluence XML，含 `ac:*` tag，**請一律用 `body.view`**。

## 完整標準流程

```powershell
# === 步驟一：貼入 Helper 定義（每次 PowerShell session 一次）===
# ... 貼入上方所有函數定義 ...

# === 步驟二：建立連線（只需一次，popup 只出現一次）===
Connect-WikiCDP

# === 步驟三：搜尋（後續不再跳 popup）===
$results = Invoke-WikiCDP "fetch('/rest/api/content/search?cql=text+~+%22HK+未轉單%22&limit=5',{credentials:'include'}).then(r=>r.json()).then(d=>JSON.stringify(d.results.map(p=>({id:p.id,title:p.title}))))"
$results | ConvertFrom-Json | Format-Table id, title -AutoSize

# === 步驟四：讀取頁面 ===
$content = Invoke-WikiCDP "fetch('/rest/api/content/54716193?expand=body.view',{credentials:'include'}).then(r=>r.json()).then(d=>{const t=document.createElement('div');t.innerHTML=d.body.view.value;return t.innerText})"
Write-Host $content

# === 結束時中斷連線（可選）===
Disconnect-WikiCDP
```

## 前置條件

Chrome 需啟用 Remote Debugging（只需做一次）：
1. 在 Chrome 網址列輸入 `chrome://inspect/#remote-debugging`
2. 勾選「Discover network targets」
3. Chrome 主動開啟後 `%LOCALAPPDATA%\Google\Chrome\User Data\DevToolsActivePort` 會自動出現

Chrome 必須已開啟 **至少一個 wiki.91app.com 的分頁**（已登入狀態）。

## 常見問題

| 問題 | 解法 |
|------|------|
| `找不到 wiki.91app.com tab` | 在 Chrome 手動開啟 wiki.91app.com 並登入 |
| `DevToolsActivePort` 不存在 | Chrome 未啟用 Remote Debugging，依前置條件設定 |
| 搜尋結果為空 | 換更短的關鍵字，或拆開為多個關鍵字分次搜尋 |
| fetch 回傳 401 | wiki tab 登入已過期，在 Chrome 重新登入 |
| WebSocket 403 | 改用 PowerShell WebSocket（非 playwright-core），因為 Chrome 做 Origin 檢查 |
