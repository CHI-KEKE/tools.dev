

## 看結構

tree /F


## 直接開資料夾

start .


## 找到特定資料夾


先跳到附近 cd /

```powershell
## 需要記住的位置
##  /
##  Users


##人在附近只知道資料夾名稱
cd (Get-ChildItem -Directory -Recurse -Depth 5 -Filter *shopping2* -ErrorAction SilentlyContinue | Select-Object -First 1).FullName

## 自訂根目錄 + 找特定資料夾
cd (Get-ChildItem C:\ -Directory -Recurse -Depth 5 -Filter *shopping2* -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
```


## 跑專案 (.NET)


```powershell
dotnet build NineYi.Sms.sln
dotnet build NineYi.Sms.sln 2>&1 | Select-String "error CS"
dotnet build NineYi.Sms.sln --no-incremental 2>&1 | findstr /C:"error CS" /C:"error MSB"
```

## 搬移特定 proj 到特定資料夾

1. windows explorer 手搬

2. 到 sln 層
```bash
dotnet sln list
```


你現在實體已經是（剛剛搬過）
Common\Nine1.Livebuy.Common.Translations\Nine1.Livebuy.Common.Translations.csproj

但 .sln 還記得的是
Nine1.Livebuy.Common.Translations\Nine1.Livebuy.Common.Translations.csproj

.sln 還留著「舊路徑的 project 紀錄」
所以 dotnet sln add 以為你在重複加入同一個 project


3. 先把舊路徑的 project 從 solution 移掉

```bash
dotnet sln remove Nine1.Livebuy.Common.Translations\Nine1.Livebuy.Common.Translations.csproj
```

4. 再加入「正確的新實體路徑」

```bash
dotnet sln add Common\Nine1.Livebuy.Common.Translations\Nine1.Livebuy.Common.Translations.csproj
```

5. 驗證

```bash
dotnet sln list
```


## 設定快速路徑

加環境變數, 要記得加在 Path 裡面


## 建立檔案

```bash
## App 檔案建立
New-Item server.js -ItemType File

## Dockerfile 建立
New-Item Dockerfile
```


## 從輸入的每一行中，找出特定文字

```bash
docker images | Select-String hello-dockerfile
```



## 安裝 uv

uv 是一個超快的 Python 套件與工具管理器
由 Astral（ruff、uvicorn 那家）開發，用 Rust 寫的
uv = 現代版、速度爆快、把 pip / pipx / venv 合體的工具

```bash
irm https://astral.sh/uv/install.ps1 | iex

uv --version
```
##  v 安裝工具

```bash
uv tool install specify-cli
```


## 使用 specify

```bash
specify --help
```






## ps 版本確認


```bash
$PSVersionTable


$PSVersionTable.PSVersion
```

## 看 profile


```bash
notepad $PROFILE
```



## choco

choco install powershell-core -y

pwsh --version



## 分割

右邊新增 alt + shift + +
下面新增 alt + shift + -
關閉某個分割 ctrl + shift + w


把焦點移到左 pane（Alt + ←）

alt + tab 切工作



## 註冊服務


New-Service -Name "WindowsTaskManager.Monitor" -BinaryPathName "D:\windows-task-manager\worker\WindowsTaskManager.Monitor.exe" -DisplayName "Windows Task Manager Monitor" -Description "排程監控服務：偵測漏排/失敗/心跳停止並發送 Slack 告警" -StartupType Automatic