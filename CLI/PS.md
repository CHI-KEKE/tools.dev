# PowerShell 指令參考

## 目錄
- [curl 指令](#curl-指令)
  - [Header 檢視](#header-檢視)
- [網路連線測試](#網路連線測試)
  - [基本連線測試](#基本連線測試)
  - [TCP Port 測試](#tcp-port-測試)
  - [HTTP 回應測試](#http-回應測試)
- [DNS 解析](#dns-解析)
  - [Domain 轉 IP](#domain-轉-ip)
  - [IP 轉 Domain](#ip-轉-domain)
- [網路連線狀態](#網路連線狀態)
  - [監聽服務查詢](#監聽服務查詢)
  - [特定 Port 查詢](#特定-port-查詢)
  - [連線狀態查詢](#連線狀態查詢)
- [環境變數管理](#環境變數管理)
  - [暫時設定環境變數](#暫時設定環境變數)
  - [永久設定環境變數](#永久設定環境變數)

<br><br>

---

## curl 指令

### Header 檢視

#### 只想要看 Header

當你只需要檢視 HTTP 回應的 Header 資訊而不需要完整內容時，可以使用 `-I` 參數。

<br>

**指令格式**

```powershell
curl.exe -I https://www.google.com
```

<br>

**參數說明**

| 參數 | 功能 | 說明 |
|------|------|------|
| `-I` | Head only | 只取得 HTTP Header，不下載完整內容 |
| `curl.exe` | 明確指定 | 在 Windows 中明確使用 curl.exe 避免別名衝突 |

<br>

**使用場景**

- 檢查網站是否可訪問
- 查看 HTTP 狀態碼
- 檢視回應標頭（如 Content-Type、Server 等）
- 測試重定向設定
- 快速檢測網站回應時間

<br>

**範例輸出**

```
HTTP/2 200
date: Fri, 27 Sep 2025 10:30:00 GMT
expires: -1
cache-control: private, max-age=0
content-type: text/html; charset=ISO-8859-1
server: gws
x-xss-protection: 0
x-frame-options: SAMEORIGIN
set-cookie: 1P_JAR=2025-09-27-10; expires=Sun, 27-Oct-2025 10:30:00 GMT; path=/; domain=.google.com; Secure
```

<br><br>

---

## 網路連線測試

### 基本連線測試

#### 自己是否能連到網路

**使用 ping 指令**

```powershell
ping www.google.com
ping 8.8.8.8
```

<br>

⚠️ **重要提醒**

有些防火牆 / 路由器 / 伺服器會把 ICMP（Ping 用的協定）擋掉。
所以「Ping 不通」不一定代表真的沒網路。

<br>

**使用 PowerShell 原生指令**

```powershell
Test-Connection www.google.com -Count 4
```

<br>

**指令比較**

| 指令 | 協定 | 特點 |
|------|------|------|
| `ping` | ICMP | 傳統指令，可能被防火牆阻擋 |
| `Test-Connection` | ICMP | PowerShell 原生，提供更多選項 |

<br>

### TCP Port 測試

#### 測試 TCP Port 是否能通

```powershell
Test-NetConnection www.google.com -Port 443
```

<br>

**常用 Port 測試範例**

| 服務 | Port | 指令範例 |
|------|------|----------|
| HTTPS | 443 | `Test-NetConnection www.google.com -Port 443` |
| HTTP | 80 | `Test-NetConnection www.google.com -Port 80` |
| SSH | 22 | `Test-NetConnection server.com -Port 22` |
| RDP | 3389 | `Test-NetConnection server.com -Port 3389` |
| SQL Server | 1433 | `Test-NetConnection db.server.com -Port 1433` |

<br>

### HTTP 回應測試

#### 抓 HTTP 回應

```powershell
Invoke-WebRequest -Uri "https://www.google.com" -Method Head
```

<br>

**參數說明**

| 參數 | 說明 |
|------|------|
| `-Uri` | 目標網址 |
| `-Method Head` | 只取得 Header，不下載完整內容 |

<br><br>

---

## DNS 解析

### Domain 轉 IP

#### 查詢域名對應的 IP 位址

```powershell
nslookup www.google.com
```

<br>

**範例輸出**

```
Server:  dns.google
Address:  8.8.8.8

Non-authoritative answer:
Name:    www.google.com
Address:  142.250.191.36
```

<br>

### IP 轉 Domain

#### 反向 DNS 查詢

```powershell
nslookup 8.8.8.8
```

<br>

**DNS 查詢工具比較**

| 工具 | 特點 | 使用場景 |
|------|------|----------|
| `nslookup` | 傳統 DNS 查詢工具 | 基本 DNS 查詢 |
| `Resolve-DnsName` | PowerShell 原生 | 更多查詢選項和輸出格式 |

<br><br>

---

## 網路連線狀態

### 監聽服務查詢

#### 顯示目前電腦上的網路連線狀態

`netstat` 指令可以告訴你：
- 哪些 Port 正在「監聽」（LISTENING）
- 哪些連線是已建立（ESTABLISHED）、等待中（TIME_WAIT）
- 哪個程式（PID）佔用了這些連線

<br>

#### 看有哪些服務正在監聽

```powershell
netstat -ano | findstr LISTEN
```

<br>

### 特定 Port 查詢

#### 看特定 Port 被誰用

```powershell
netstat -ano | findstr :5000
```

<br>

**常用 Port 查詢範例**

```powershell
# 查看 Web 服務
netstat -ano | findstr :80
netstat -ano | findstr :443

# 查看資料庫服務
netstat -ano | findstr :1433
netstat -ano | findstr :3306

# 查看開發服務
netstat -ano | findstr :3000
netstat -ano | findstr :8080
```

<br>

### 連線狀態查詢

#### 看目前建立的連線

```powershell
netstat -ano
```

<br>

**netstat 參數說明**

| 參數 | 功能 |
|------|------|
| `-a` | 顯示所有連線和監聽的 Port |
| `-n` | 以數字格式顯示位址和 Port |
| `-o` | 顯示擁有每個連線的程序 ID (PID) |

<br>

**連線狀態說明**

| 狀態 | 說明 |
|------|------|
| `LISTENING` | Port 正在監聽，等待連線 |
| `ESTABLISHED` | 連線已建立 |
| `TIME_WAIT` | 連線關閉後的等待狀態 |
| `CLOSE_WAIT` | 等待應用程式關閉連線 |

<br>

**實用查詢組合**

```powershell
# 查看所有監聽的 Port 並排序
netstat -ano | findstr LISTEN | sort

# 查看特定程式的連線 (以 PID 查詢)
netstat -ano | findstr 1234

# 查看外部連線
netstat -ano | findstr ESTABLISHED
```

<br><br>

---

## 環境變數管理

### 暫時設定環境變數

#### 設定和讀取環境變數

**設定環境變數**

```powershell
# 設定環境變數
$Env:MY_VAR = "HelloWorld"
```

<br>

**讀取環境變數**

```powershell
# 讀取環境變數 - 方法一
Write-Output $Env:MY_VAR

# 讀取環境變數 - 方法二
$Env:MY_VAR
```

<br>

⚠️ **重要提醒**

注意：關閉 PowerShell 後，這個變數就會消失。

<br>

### 永久設定環境變數

#### 永久設定（使用者或系統環境變數）

**設定使用者環境變數**

```powershell
# 設定使用者環境變數（只影響自己）
[System.Environment]::SetEnvironmentVariable("MY_VAR", "HelloWorld", "User")
```

<br>

**設定系統環境變數**

```powershell
# 設定系統環境變數（需以管理員權限執行）
[System.Environment]::SetEnvironmentVariable("MY_VAR", "HelloWorld", "Machine")
```

<br>

**參數說明**

| 參數位置 | 範例 | 功能說明 |
|----------|------|----------|
| 1 | `"MY_VAR"` | 環境變數名稱 |
| 2 | `"HelloWorld"` | 要設定的值 |
| 3 | `"Machine"` | 生效範圍（Process/User/Machine） |

<br>

**生效範圍比較**

| 範圍 | 說明 | 適用場景 | 權限需求 |
|------|------|----------|----------|
| `Process` | 只在當前程序中生效 | 臨時變數 | 一般使用者 |
| `User` | 只影響當前使用者 | 個人設定 | 一般使用者 |
| `Machine` | 影響所有使用者 | 系統設定 | 管理員權限 |

<br>

**實用範例**

```powershell
# 設定開發環境變數
[System.Environment]::SetEnvironmentVariable("NODE_ENV", "development", "User")

# 設定 PATH 環境變數（追加路徑）
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$newPath = "$currentPath;C:\MyTools"
[System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

# 查看所有環境變數
Get-ChildItem Env:

# 查看特定環境變數
[System.Environment]::GetEnvironmentVariable("MY_VAR", "User")
```

<br>

**刪除環境變數**

```powershell
# 刪除使用者環境變數
[System.Environment]::SetEnvironmentVariable("MY_VAR", $null, "User")

# 刪除系統環境變數（需管理員權限）
[System.Environment]::SetEnvironmentVariable("MY_VAR", $null, "Machine")
```