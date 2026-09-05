<#
.SYNOPSIS
    從 Nine1 樣板產生新的 .NET 專案

.DESCRIPTION
    此腳本封裝 dotnet new 指令，支援兩種 Nine1 樣板：
      - webapi：Nine1.ThreeTierCustomWebApiTemplate（三層式 REST Web API）
      - nmqv3 ：Nine1.NMQv3Template（NMQ v3 Console Worker）
    PREFIX 固定為 Nine1，專案名稱建議使用 kebab-case 格式。

.PARAMETER TemplateType
    樣板類型：webapi（預設）或 nmqv3

.PARAMETER Name
    專案名稱，使用 kebab-case（例：order-management），不可含 nine1- 前綴（系統自動去除）

.PARAMETER ParentDir
        專案父目錄路徑，實際資料夾名稱依樣板自動派生：
            - webapi：Nine1.{CamelCase}.Web.Api
            - nmqv3 ：Nine1.{CamelCase}.Worker
    預設：C:\91app

.PARAMETER Struct
    架構類型（僅 webapi 有效）：module（收攏式，預設）或 flat（攤平式）

.PARAMETER DatabaseSecret
    資料庫密鑰類型：none（預設）、postgresql、mssql

.PARAMETER Namespace
    Namespace 輸入（可含環境前綴 qa- / pp- / prod-，系統自動辨識並統一派生三環境值）
    例：pp-pokemon-center → QA=qa-pokemon-center, PP=pp-pokemon-center, Prod=prod-pokemon-center
    若不提供，預設以專案名稱（--name）派生

.PARAMETER APIHost
    API ingress host 基礎名稱（僅 webapi 有效，不含環境與網域）
    預設：{name}-internal
    例：litecrm-api → litecrm-api-internal

.PARAMETER TemplateRoot
    樣板根目錄路徑（預設自動偵測）

.EXAMPLE
    .\scaffold.ps1 -TemplateType webapi -Name "order-management" -ParentDir "C:\projects"
    # 產生於 C:\projects\Nine1.OrderManagement.Web.Api，namespace 自動帶入 qa/pp/prod-order-management

.EXAMPLE
    .\scaffold.ps1 -TemplateType webapi -Name "user-service" -ParentDir "D:\repos" -Struct flat -DatabaseSecret postgresql

.EXAMPLE
    .\scaffold.ps1 -TemplateType nmqv3 -Name "order-consumer" -ParentDir "C:\projects"
    # 產生於 C:\projects\Nine1.OrderConsumer.Worker

.EXAMPLE
    .\scaffold.ps1 -TemplateType webapi -Name "pokemon" -ParentDir "C:\projects" -Namespace "pp-pokemon-center"
    # namespace 自動辨識 pp- 前綴 → QA=qa-pokemon-center, PP=pp-pokemon-center, Prod=prod-pokemon-center

.EXAMPLE
    .\scaffold.ps1 -TemplateType webapi -Name "litecrm-api" -ParentDir "C:\projects" -APIHost "litecrm-api-internal"
    # host 會套用為：
    #   QA   = litecrm-api-internal.qa.91dev.tw
    #   PP   = litecrm-api-internal.pp.91app.io
    #   Prod = litecrm-api-internal.91app.io
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('webapi', 'nmqv3')]
    [string]$TemplateType = 'webapi',

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z][a-z0-9]*(-[a-z0-9]+)*$')]
    [string]$Name,

    [Parameter(Mandatory = $false)]
    [string]$ParentDir = 'C:\91app',

    [Parameter(Mandatory = $false)]
    [ValidateSet('module', 'flat')]
    [string]$Struct = 'module',

    [Parameter(Mandatory = $false)]
    [ValidateSet('none', 'postgresql', 'mssql')]
    [string]$DatabaseSecret = 'none',

    [Parameter(Mandatory = $false)]
    [string]$Namespace = '',

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-z0-9]([a-z0-9-]*[a-z0-9])?$')]
    [string]$APIHost = '',

    [Parameter(Mandatory = $false)]
    [string]$TemplateRoot = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# 自動去除意外輸入的 nine1- 前綴（避免產生 Nine1.Nine1.Something）
if ($Name -match '^nine1-(.+)$') {
    Write-Warning "偵測到 'nine1-' 前綴，自動去除：'$Name' → '$($Matches[1])'"
    $Name = $Matches[1]
}

# 早期計算 CamelCase，用於派生輸出目錄
function ConvertTo-TitleCase([string]$text) {
    return (Get-Culture).TextInfo.ToTitleCase($text.Replace('-', ' ')).Replace(' ', '')
}

$fqdnSuffix = $Name -replace '-', '.'
$fqdnSuffix = ($fqdnSuffix -split '\.' | ForEach-Object {
    $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()
}) -join '.'
$camelCase = $fqdnSuffix -replace '\.', ''
$snakeUpper = ($Name -replace '-', '_').ToUpper()

# 由 ParentDir + Nine1.CamelCase.<Web.Api|Worker> 自動派生輸出目錄
$resolvedParent = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ParentDir)
$outputSuffix = if ($TemplateType -eq 'nmqv3') { 'Worker' } else { 'Web.Api' }
$resolvedOutput = Join-Path $resolvedParent "Nine1.$camelCase.$outputSuffix"

# 派生三環境 namespace
# 若 -Namespace 含環境前綴（qa- / pp- / prod-），剝除得到基礎名稱，再統一套用
if ($Namespace -match '^(qa|pp|prod)-(.+)$') {
    $nsBase = $Matches[2]
    Write-Host "[INFO] 偵測到環境前綴 '$($Matches[1])-'，基礎名稱：$nsBase" -ForegroundColor DarkCyan
} elseif ($Namespace -ne '') {
    $nsBase = $Namespace
} else {
    $nsBase = $Name
}
$NamespaceQA   = "qa-$nsBase"
$NamespacePP   = "pp-$nsBase"
$NamespaceProd = "prod-$nsBase"

# 派生 ingress host（僅 webapi 使用）
$apiHostBase = if ($APIHost -ne '') { $APIHost } else { "$Name-internal" }
$apiHostQA   = "$apiHostBase.qa.91dev.tw"
$apiHostPP   = "$apiHostBase.pp.91app.io"
$apiHostProd = "$apiHostBase.91app.io"

# ─── 前置檢查 ────────────────────────────────────────────────────────────────

# 確認 dotnet 已安裝
try {
    $dotnetVersion = (dotnet --version 2>&1)
    Write-Host "[OK] .NET SDK: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Error ".NET SDK 未安裝，請前往 https://dotnet.microsoft.com/download 下載安裝後再試。"
    exit 1
}

# 解析樣板目錄
if (-not $TemplateRoot) {
    # 自動找尋樣板：樣板就在此 Skill 目錄的 template/ 底下
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $skillDir = Split-Path -Parent $scriptDir
    $templateName = if ($TemplateType -eq 'nmqv3') { 'Nine1.NMQv3Template' } else { 'Nine1.ThreeTierCustomWebApiTemplate' }
    $TemplateRoot = Join-Path $skillDir "template\$templateName"
}

if (-not (Test-Path $TemplateRoot)) {
    Write-Error "找不到樣板目錄：$TemplateRoot`n請確認樣板路徑正確，或使用 -TemplateRoot 參數手動指定。"
    exit 1
}

Write-Host "[OK] 樣板類型：$TemplateType" -ForegroundColor Green
Write-Host "[OK] 樣板目錄：$TemplateRoot" -ForegroundColor Green

# 確認輸出目錄不衝突
if (Test-Path $resolvedOutput) {
    Write-Warning "輸出目錄已存在：$resolvedOutput"
    $confirm = Read-Host "要繼續並覆蓋現有內容嗎？[y/N]"
    if ($confirm -notin @('y', 'Y')) {
        Write-Host "已取消。" -ForegroundColor Yellow
        exit 0
    }
}

# ─── 顯示命名轉換預覽 ────────────────────────────────────────────────────────

Write-Host ""
Write-Host "── 命名轉換預覽 ─────────────────────────────────" -ForegroundColor Cyan
Write-Host "  樣板類型        : $TemplateType"
Write-Host "  FQDN            : Nine1.$fqdnSuffix"
Write-Host "  CamelCase       : Nine1.$camelCase"
Write-Host "  kebab-case      : nine1-$Name"
Write-Host "  SNAKE_UPPER     : NINE1_$snakeUpper"
Write-Host "  輸出目錄        : $resolvedOutput"
Write-Host "  Namespace QA    : $NamespaceQA"
Write-Host "  Namespace PP    : $NamespacePP"
Write-Host "  Namespace Prod  : $NamespaceProd"
if ($TemplateType -eq 'webapi') {
    Write-Host "  架構類型        : $Struct"
    Write-Host "  API Host QA     : $apiHostQA"
    Write-Host "  API Host PP     : $apiHostPP"
    Write-Host "  API Host Prod   : $apiHostProd"
}
Write-Host "  資料庫密鑰      : $DatabaseSecret"
Write-Host "─────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "確認以上設定並繼續？[Y/n]"
if ($confirm -in @('n', 'N')) {
    Write-Host "已取消。" -ForegroundColor Yellow
    exit 0
}

# ─── 初始化 AI 指引（.github 目錄）────────────────────────────────────────────────────

$glToken = ''
if (-not $glToken) {
    Write-Warning "[前置] 未提供 GitLab Token，跳過 AI 指引初始化"
} else {
    Write-Host ""
    Write-Host "[前置] 初始化 .github AI 指引..." -ForegroundColor Cyan

    $glProjectUrl = "https://gitlab.91app.com/api/v4/projects/b2e%2Fnine1.copilot.instructions"
    $glBranch     = 'main'
    $glHeaders    = @{ 'PRIVATE-TOKEN' = $glToken }

    function Get-GitLabTree {
        param([string]$SrcPath)
        $items = @()
        $page  = 1
        do {
            $encoded = [Uri]::EscapeDataString($SrcPath)
            $url     = "$glProjectUrl/repository/tree?path=$encoded&ref=$glBranch&recursive=true&per_page=100&page=$page"
            $batch   = Invoke-RestMethod -Uri $url -Headers $glHeaders -ErrorAction Stop
            $items  += $batch
            $page++
        } while ($batch.Count -eq 100)
        return $items
    }

    function Save-GitLabFile {
        param([string]$SrcPath, [string]$DstAbsPath)
        $encoded = [Uri]::EscapeDataString($SrcPath)
        $url = "$glProjectUrl/repository/files/$encoded/raw?ref=$glBranch"
        $dir = Split-Path -Parent $DstAbsPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Invoke-RestMethod -Uri $url -Headers $glHeaders -OutFile $DstAbsPath -ErrorAction Stop
    }

    # 資料夾對應：src/.github/xxx → <output>/.github/xxx
    $folderMappings = @(
        @{ Src = 'src/.github/skills/b2e';      Dst = '.github/skills'     }
        @{ Src = 'src/.github/ps';              Dst = '.github/ps'         }
        @{ Src = 'src/.github/agents/speckit';  Dst = '.github/agents'     }
        @{ Src = 'src/.github/agents/v2.4';     Dst = '.github/agents'     }
        @{ Src = 'src/.github/checklists';      Dst = '.github/checklists' }
        @{ Src = 'src/.specify';                Dst = '.specify'           }
    )

    # 單一檔案對應
    $constitutionSrc = if ($TemplateType -eq 'nmqv3') {
        'src/.specify/memory/nmqv3/constitution.md'
    } else {
        'src/.specify/memory/api/constitution.md'
    }
    $fileMappings = @(
        @{ Src = 'src/.github/copilot-instructions/DotNet/copilot-instructions.md';     Dst = '.github/copilot-instructions.md'                          }
        @{ Src = 'src/.github/instructions/DotNet/code_generation.instructions.md'; Dst = '.github/instructions/code_generation.instructions.md' }
        @{ Src = 'src/.github/instructions/unit_test_generation.instructions.md'; Dst = '.github/instructions/unit_test_generation.instructions.md' }
        @{ Src = $constitutionSrc;                                                   Dst = '.specify/memory/constitution.md'                          }
    )

    $dlErrors = 0

    foreach ($mapping in $folderMappings) {
        try {
            $items = Get-GitLabTree -SrcPath $mapping.Src
            $blobs = $items | Where-Object { $_.type -eq 'blob' }
            foreach ($blob in $blobs) {
                $relPath = $blob.path.Substring($mapping.Src.Length).TrimStart('/')
                $dstAbs  = Join-Path $resolvedOutput ($mapping.Dst.Replace('/', '\') + '\' + $relPath.Replace('/', '\'))
                Save-GitLabFile -SrcPath $blob.path -DstAbsPath $dstAbs
                Write-Host "  [DL] $($blob.path)" -ForegroundColor DarkGreen
            }
        } catch {
            Write-Warning "  [WARN] 資料夾 $($mapping.Src)：$_"
            $dlErrors++
        }
    }

    foreach ($mapping in $fileMappings) {
        try {
            $dstAbs = Join-Path $resolvedOutput $mapping.Dst.Replace('/', '\')
            Save-GitLabFile -SrcPath $mapping.Src -DstAbsPath $dstAbs
            Write-Host "  [DL] $($mapping.Src)" -ForegroundColor DarkGreen
        } catch {
            Write-Warning "  [WARN] 檔案 $($mapping.Src)：$_"
            $dlErrors++
        }
    }

    # constitution.md：將 Sample 相關佔位字串替換為實際專案名稱
    $constitutionDst = Join-Path $resolvedOutput '.specify\memory\constitution.md'
    if (Test-Path $constitutionDst) {
        $humanName = $fqdnSuffix -replace '\.', ' '   # "Order.Management" → "Order Management"
        $content   = Get-Content $constitutionDst -Raw -Encoding UTF8
        $content   = $content -replace 'Nine1\.Sample\.Project', "Nine1.$fqdnSuffix"
        $content   = $content -replace 'Sample\.Project',        $fqdnSuffix
        $content   = $content -replace 'Nine1\.SampleProject',   "Nine1.$camelCase"
        $content   = $content -replace 'SampleProject',          $camelCase
        $content   = $content -replace 'SAMPLE_PROJECT',         $snakeUpper
        $content   = $content -replace 'nine1-sample-project',   "nine1-$Name"
        $content   = $content -replace 'sample-project',         $Name
        $content   = $content -replace 'Sample Project',         $humanName
        $content   = $content -replace 'Sample Service',         $humanName
        Set-Content $constitutionDst -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  [OK] constitution.md 名稱替換完成 → Nine1.$fqdnSuffix" -ForegroundColor Green
    }

    if ($dlErrors -eq 0) {
        Write-Host "  [OK] AI 指引初始化完成" -ForegroundColor Green
    } else {
        Write-Warning "  AI 指引部分下載失敗（$dlErrors 個），請手動補充或確認腳本內建 Token 是否有效"
    }
}

# ─── 安裝樣板 ────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[1/2] 安裝樣板..." -ForegroundColor Cyan
dotnet new install "$TemplateRoot" --force
if ($LASTEXITCODE -ne 0) {
    Write-Error "樣板安裝失敗（exit code: $LASTEXITCODE）。請確認路徑正確。"
    exit 1
}
Write-Host "[OK] 樣板安裝成功" -ForegroundColor Green

# ─── 產生專案 ────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[2/2] 產生專案..." -ForegroundColor Cyan
if ($TemplateType -eq 'nmqv3') {
    dotnet new dotnet.nmqv3.worker `
        --name "$Name" `
        --output "$resolvedOutput" `
        --databaseSecret "$DatabaseSecret"
} else {
    dotnet new dotnet.webapi.custom `
        --name "$Name" `
        --output "$resolvedOutput" `
        --struct "$Struct" `
        --databaseSecret "$DatabaseSecret"
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "專案產生失敗（exit code: $LASTEXITCODE）。"
    exit 1
}

# ─── 替換 K8s Namespace ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[變更部署設定] Namespace 替換..." -ForegroundColor Cyan

$qaFile = Join-Path $resolvedOutput 'nine1-devops-deployments.QA.json'
if (Test-Path $qaFile) {
    $qa = Get-Content $qaFile -Raw | ConvertFrom-Json
    $qa.spec.deployments | ForEach-Object { $_.settings.NAMESPACE = $NamespaceQA }
    $qa | ConvertTo-Json -Depth 10 | Set-Content $qaFile -Encoding UTF8
    Write-Host "  [OK] QA   namespace = $NamespaceQA" -ForegroundColor Green
} else {
    Write-Warning "  找不到 $qaFile，跳過"
}

$prodFile = Join-Path $resolvedOutput 'nine1-devops-deployments.Prod.json'
if (Test-Path $prodFile) {
    $prod = Get-Content $prodFile -Raw | ConvertFrom-Json
    $prod.spec.deployments | ForEach-Object {
        if ($_.metadata.env -eq 'PP')   { $_.settings.NAMESPACE = $NamespacePP }
        if ($_.metadata.env -eq 'Prod') { $_.settings.NAMESPACE = $NamespaceProd }
    }
    $prod | ConvertTo-Json -Depth 10 | Set-Content $prodFile -Encoding UTF8
    Write-Host "  [OK] PP   namespace = $NamespacePP" -ForegroundColor Green
    Write-Host "  [OK] Prod namespace = $NamespaceProd" -ForegroundColor Green
} else {
    Write-Warning "  找不到 $prodFile，跳過"
}

if ($TemplateType -eq 'webapi') {
    Write-Host ""
    Write-Host "[變更 charts] ingress host 與 canary customMetrics.query ..." -ForegroundColor Cyan

    function Update-ApiValuesYaml {
        param(
            [string]$FilePath,
            [string]$IngressHost,
            [string]$ExportedNamespace
        )

        if (-not (Test-Path $FilePath)) {
            Write-Warning "  找不到 $FilePath，跳過"
            return
        }

        $content = Get-Content $FilePath -Raw -Encoding UTF8

        # 更新 ingress host
        $content = [regex]::Replace(
            $content,
            '(?m)^(\s*-\s*host:\s*).*$' ,
            ('$1' + $IngressHost)
        )

        # 更新 canary query 並帶入 exported_namespace
        $newQuery = 'rate(nginx_ingress_controller_requests{namespace="ingress-nginx", ingress="{{ ingress }}",exported_namespace="' + $ExportedNamespace + '"}[2m])'
        $content = [regex]::Replace(
            $content,
            "(?m)^(\\s*)query:\\s*'.*'$",
            ('$1' + "query: '$newQuery'")
        )

        Set-Content $FilePath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  [OK] $(Split-Path -Leaf $FilePath) host=$IngressHost, exported_namespace=$ExportedNamespace" -ForegroundColor Green
    }

    $chartDir = Join-Path $resolvedOutput ("charts\{0}-web-api" -f $Name)
    Update-ApiValuesYaml -FilePath (Join-Path $chartDir 'values-tw-qa.yaml')   -IngressHost $apiHostQA   -ExportedNamespace $NamespaceQA
    Update-ApiValuesYaml -FilePath (Join-Path $chartDir 'values-tw-pp.yaml')   -IngressHost $apiHostPP   -ExportedNamespace $NamespacePP
    Update-ApiValuesYaml -FilePath (Join-Path $chartDir 'values-tw-prod.yaml') -IngressHost $apiHostProd -ExportedNamespace $NamespaceProd
}

# ─── 完成摘要 ────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  專案產生成功！" -ForegroundColor Green
Write-Host "  位置：$resolvedOutput" -ForegroundColor Green
Write-Host "  Namespace QA   : $NamespaceQA" -ForegroundColor Green
Write-Host "  Namespace PP   : $NamespacePP" -ForegroundColor Green
Write-Host "  Namespace Prod : $NamespaceProd" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "後續步驟建議：" -ForegroundColor Yellow
if ($TemplateType -eq 'nmqv3') {
    Write-Host "  1. 開啟方案：  $resolvedOutput\src\Nine1.$fqdnSuffix.Console.NMQv3Worker.sln"
    Write-Host "  2. 設定連線：  $resolvedOutput\src\Nine1.$fqdnSuffix.Console.NMQv3Worker\appsettings.Development.json"
} else {
    Write-Host "  1. 開啟方案：  $resolvedOutput\src\Nine1.$fqdnSuffix.Web.Api.code-workspace"
    Write-Host "  2. 設定連線：  $resolvedOutput\src\Nine1.$fqdnSuffix.Web.Api\appsettings.Development.json"
}
if ($DatabaseSecret -ne 'none') {
    Write-Host "  3. 設定 $DatabaseSecret 密鑰：請參考 config/ 目錄下的相關設定檔"
}
Write-Host ""

# ─── Git 初始化 ──────────────────────────────────────────────────────────────

Write-Host "[Git] 初始化 git 倉庫..." -ForegroundColor Cyan
Push-Location $resolvedOutput
try {
    git init | Out-Null
    git add -A | Out-Null
    git commit -m "chore: initial project scaffold from Nine1 template" | Out-Null
    Write-Host "  [OK] git init + 初始 commit 完成" -ForegroundColor Green
} catch {
    Write-Warning "  [WARN] Git 初始化失敗：$_"
} finally {
    Pop-Location
}
Write-Host ""
