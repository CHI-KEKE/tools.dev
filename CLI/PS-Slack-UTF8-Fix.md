# PowerShell Slack 告警中文亂碼問題排查紀錄

## 問題描述

`nine1.live.buy.cronjob` 的 `sync-live-comments.ps1` 定期執行，當 NMQ 任務建立失敗時會送出 Slack 告警。  
但實際收到的告警訊息，所有中文字全部變成 `?`：

```
??????Job : SyncLiveSessionComment NMQ ????Market
hkEnvironment
QAResult
:x: 1 ? Session ???? / ? 1 ?
:warning: ??? NMQ ????????????????
```

---

## 根本原因：`Invoke-RestMethod` 預設不使用 UTF-8 編碼傳送 Body

### 問題程式碼（修改前）

```powershell
$slackBody = @{ ... } | ConvertTo-Json -Depth 10   # 產生 string

Invoke-RestMethod -Uri $SlackWebhookUrl -Method POST -Body $slackBody -ContentType 'application/json' -ErrorAction Stop
```

**關鍵問題：**

- `ConvertTo-Json` 產生的是 PowerShell `string` 物件（Unicode）
- `Invoke-RestMethod` 接收 `string` 型別的 `-Body` 時，使用**系統預設編碼**傳送
- Windows 環境預設編碼為 **Windows-1252 / Big5 (CP950)**，無法正確表示 UTF-8 多 byte 中文字
- 每個中文字被截斷 → 變成一個 `?`

### 佐證

| 原始中文 | 字數 | 告警顯示 |
|---|---|---|
| `直播留言同步` | 6 字 | `??????` |
| `建立失敗` | 4 字 | `????` |
| `個` | 1 字 | `?` |

每個中文字 = 一個 `?`，完全符合單 byte 截斷特徵。

---

## 解法：明確將 Body 轉為 UTF-8 byte array 再傳送

```powershell
# 修改後：明確轉 UTF-8 bytes
$slackBodyBytes = [System.Text.Encoding]::UTF8.GetBytes($slackBody)
Invoke-RestMethod -Uri $SlackWebhookUrl -Method POST -Body $slackBodyBytes -ContentType 'application/json; charset=utf-8' -ErrorAction Stop
```

兩個改動：
1. `$slackBody`（string）→ `[System.Text.Encoding]::UTF8.GetBytes($slackBody)`（byte[]）
2. `-ContentType` 補上 `; charset=utf-8`

---

## 附帶修正：Slack 告警文案調整

同步將警告說明文案從：

> 請確認 NMQ 是否有繼續建立並確認訊息同步狀況，如需手動補留言同步請參考 SOP 文件

改為更清楚的：

> 請確認 MQ 是否有繼續建立並確認訊息同步狀況，若有持續 fail 繼續觀察同步狀況即可，如需手動補同步留言請參考 SOP 文件

---

## 涉及檔案

| 檔案 | 異動內容 |
|---|---|
| `src/Nine1.Live.Buy.CreateTask/script/sync-live-comments.ps1` | 修正 `Invoke-RestMethod` 編碼 + 更新告警文案 |

---

## 補充：本地 .ps1 腳本中文壞字問題

排查過程中發現，在 Windows 用 `Set-Content -Encoding UTF8` 或工具寫入 `.ps1` 時，  
若沒有 **UTF-8 BOM**，PowerShell 5.x 會以系統編碼（Big5）讀取 → 中文 parse 錯誤、腳本直接噴錯。

**正確寫法：**

```powershell
[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($true))
#                                                                                  ^^^^ $true = with BOM
```

這樣 PowerShell 5.x 才能正確讀到 UTF-8 中文字。

---

## 結論

| 情境 | 問題 | 解法 |
|---|---|---|
| `Invoke-RestMethod` 送中文 JSON | 預設用系統編碼 → Slack 收到亂碼 | 轉 UTF-8 byte array 再送 |
| 寫 `.ps1` 含中文 | PS5 以 Big5 讀 → parse 失敗 | 寫入時加 UTF-8 BOM |