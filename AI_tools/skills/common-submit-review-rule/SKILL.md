---
name: submit-review-rule
description: 引導 RD 透過對話提交新的 Code Review 規則，取代 Excel 表單流程。自動分配 Key 編號、產生中英文雙語 MD 文件，並建立 GitLab Merge Request。
metadata:
  pattern: pipeline
  interaction: multi-turn
  steps: "4"
  repo: nine1.ai_code_review
---

# Submit Review Rule Skill

此 Skill 取代原本 Excel 表單的「前段提交流程」：  
RD 透過 Copilot CLI 與 AI 對話提供規則資訊，AI 自動完成 Key 分配、文件產生與 GitLab MR 建立。

**在 Phase 1 資訊收集完成並確認前，不要建立任何檔案或執行任何 git 指令。**

> **注意**：此 Skill 可在任何目錄下執行。若當前目錄不是 `nine1.ai_code_review`，  
> Skill 會自動在確認後尋找或 clone repo，RD 不需要事先準備。

---

## Phase 1 — 資訊收集

依序詢問以下問題，**每次只問一個，等待回答後再問下一個**。  
盡量提供 `choices` 讓使用者選擇，減少手動輸入。

### Q1：提供人
問：「你的名字是？（提供人）」  
自由輸入。

### Q2：規則類型（決定存放的資料夾）
問：「這個規則屬於哪個類型？」  
choices：
- `通用規則（CustomRules）` → 存至 `knowledge_base/backend/CustomRules/`
- `ExceptionRules` → 存至 `knowledge_base/backend/ExceptionRules/`
- `InformationSecurity` → 存至 `knowledge_base/backend/InformationSecurity/`
- `NMQRules` → 存至 `knowledge_base/backend/NMQRules/`
- `best-practices` → 存至 `knowledge_base/backend/best-practices/`

### Q3：Rule Title
問：「規則標題是？（簡短清楚描述規則目的，中英文皆可）」  
自由輸入。若為中文，之後文件產生時自動翻譯為英文標題。

### Q4：Severity
問：「這個規則的嚴重性？」  
choices：
- `Blocker`：最嚴重，必須立即修復
- `Critical`：重要問題，盡快修復
- `Major`：需要解決，但沒有立即風險
- `Minor`：輕微問題
- `Info`：資訊性提示

### Q5：程式語言
問：「規則適用的程式語言？」  
choices：`C#`、`JavaScript`、`TypeScript`、`Java`、`Python`、`其他`

### Q6：問題描述（Description）
問：「請描述這個規則的問題：為什麼這是個問題？可能造成什麼影響？」  
自由輸入，可多行。

### Q7：Noncompliant Code Example
問：「請提供不合規的程式碼範例（Noncompliant Code Example），並標註哪行有問題：」  
自由輸入，使用者可直接貼上程式碼（包含 `// Noncompliant` 等注解）。

### Q8：Compliant Solution
問：「請提供合規的解決方案（Compliant Solution）：」  
自由輸入，使用者可直接貼上程式碼。

### Q9：Documentation 連結（可選）
問：「有相關文件連結嗎？（PR link、VSTS link、Google Slides、Git commit 等，若無直接跳過）」  
自由輸入，可省略。

---

收集完 Q1~Q9 後，**顯示完整摘要**讓使用者確認：

```
📋 規則資訊確認

  提供人       : {Q1}
  規則類型     : {Q2}（→ {對應資料夾}）
  Rule Title   : {Q3}
  Severity     : {Q4}
  Language     : {Q5}
  Description  : {Q6 前 100 字}...
  Noncompliant : [已提供，{行數} 行]
  Compliant    : [已提供，{行數} 行]
  Documentation: {Q9 或 "(無)"}
```

詢問：「以上資訊正確嗎？要繼續產生規則文件嗎？」  
等待確認後才進入 Phase 2。

---

## Repo Setup — 自動尋找或 Clone Repo

在 Phase 1 確認後、Phase 2 開始前，執行以下 PowerShell 確認 repo 位置：

```powershell
# Step 1：檢查目前是否已在 nine1.ai_code_review repo 內
$currentRepoName = git rev-parse --show-toplevel 2>$null |
    Split-Path -Leaf

if ($currentRepoName -eq "nine1.ai_code_review") {
    $repoRoot = git rev-parse --show-toplevel
    Write-Host "✅ 已在 repo 目錄：$repoRoot"
}
# Step 2：檢查常見本機路徑
elseif (Test-Path "C:\91APP_GitLab\nine1.ai_code_review\.git") {
    $repoRoot = "C:\91APP_GitLab\nine1.ai_code_review"
    Write-Host "✅ 找到 repo：$repoRoot"
}
elseif (Test-Path "$env:USERPROFILE\source\repos\nine1.ai_code_review\.git") {
    $repoRoot = "$env:USERPROFILE\source\repos\nine1.ai_code_review"
    Write-Host "✅ 找到 repo：$repoRoot"
}
# Step 3：都找不到 → 自動 clone 到 TEMP
else {
    $repoRoot = "$env:TEMP\nine1.ai_code_review"
    if (-not (Test-Path $repoRoot)) {
        Write-Host "⬇️ 未找到本機 repo，正在 clone..."
        git clone https://gitlab.91app.com/g11n/nine1.ai_code_review.git $repoRoot
    } else {
        Write-Host "✅ 使用已 clone 的 repo：$repoRoot"
    }
}
```

確認成功後，後續所有檔案操作和 git 指令都以 `$repoRoot` 為工作目錄。

---

## Phase 2 — Key 自動分配

在 repo root（`$repoRoot`）執行以下 PowerShell 找出下一個可用的 Key：

```powershell
Set-Location $repoRoot
Get-ChildItem -Path "knowledge_base/backend" -Recurse -Filter "N*.md" |
  Where-Object { $_.Name -notmatch "_中文" } |
  ForEach-Object {
    if ($_.BaseName -match "^N(\d+)$") { [int]$Matches[1] }
  } |
  Measure-Object -Maximum |
  Select-Object -ExpandProperty Maximum
# 新 Key = Maximum + 1，格式：N{數字:00000}，例如目前最大 55 → 新 Key = N00056
```

回報：「✅ 已分配 Key：**{新Key}**」

---

## Phase 3 — 文件產生

使用 Phase 1 的資訊與 Phase 2 的 Key，建立兩個 MD 文件。  
參照 `skills/code-review-rule-generator/references/` 的模板格式。

### 放置位置
- `knowledge_base/backend/{Q2資料夾}/{Key}.md`（英文版）
- `knowledge_base/backend/{Q2資料夾}/{Key}_中文.md`（中文版）

### Repository metadata 自動對應
| Language | Repository |
|----------|-----------|
| C# | `csharpsquid` |
| JavaScript / TypeScript | `javascript` |
| Java | `java` |
| 其他 | `[repository-name]`（留待手動填寫）|

### 英文版（{Key}.md）格式

```markdown
# {英文 Rule Title}

- **Key**: {Key}
- **Repository**: {依語言自動對應}
- **Created At**: {YYYYMMDD，今天日期}
- **Severity**: {Q4 大寫，如 MAJOR}
- **Status**: READY
- **Language**: {Q5}

---

## Why is this an issue?

{Q6，翻譯為英文}

---

## **Noncompliant Code Example**

```{語言小寫，如 csharp}
{Q7 程式碼，英文注解}
```

### Issue

1. {從 Q7 和 Q6 推導出的主要問題說明}
2. {次要問題，如適用}

---

## **Compliant Solution**

```{語言小寫}
{Q8 程式碼，英文注解}
```

### Solution

1. {從 Q8 推導出的解決方式}
2. {補充說明，如適用}

---

## Additional Recommendations

1. **Code Reviews**: {程式碼審查建議}
2. **Static Analysis**: {靜態分析工具建議，如適用}
3. **Documentation**: {文件建議，如適用}

---

## Resources

{Q9 的連結，每個一行；若無則省略此章節}
```

### 中文版（{Key}_中文.md）格式

完全比照英文版結構，但：
- 所有文字內容翻譯為自然中文
- 程式碼區塊保持不變，僅將 `// Noncompliant:` 等英文注解翻譯為中文
- 章節標題改為中文（「為什麼這是個問題？」、「不合規的程式碼範例」、「合規的解決方案」等）
- 參照 `skills/code-review-rule-generator/references/chinese_template.md`

產生完後回報：
「✅ 文件已建立：
- `{目標資料夾}/{Key}.md`
- `{目標資料夾}/{Key}_中文.md`」

---

## Phase 4 — Git Branch、Commit、Push & MR

在 repo root `$repoRoot` 依序執行：

```powershell
Set-Location $repoRoot

# 1. 先拉最新 master（若是 temp clone 也確保同步）
git checkout master
git pull

# 2. 開新 branch
git checkout -b feature/add-rule-{Key}

# 3. Stage 新增的 MD 文件
git add "knowledge_base/backend/{Q2資料夾}/{Key}.md"
git add "knowledge_base/backend/{Q2資料夾}/{Key}_中文.md"

# 4. Commit（含 Co-authored-by trailer）
git commit -m "feat: 新增 Code Review 規則 {Key}

- Rule: {Q3}
- Severity: {Q4}
- Language: {Q5}
- Category: {Q2}
- 提供人: {Q1}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

# 5. Push 到 GitLab remote（origin）
git push origin feature/add-rule-{Key}
```

Push 完成後，顯示 GitLab MR 建立連結：

```
🔗 請點擊以下連結建立 Merge Request：
https://gitlab.91app.com/g11n/nine1.ai_code_review/-/merge_requests/new?merge_request[source_branch]=feature/add-rule-{Key}&merge_request[target_branch]=master&merge_request[title]=feat%3A%20{Key}%20{URLencoded-Title}
```

最終回報：「✅ 完成！規則 {Key} 的文件已 push，請開啟上方連結建立 Merge Request，合併後再手動更新 Dify Knowledge Base。」

