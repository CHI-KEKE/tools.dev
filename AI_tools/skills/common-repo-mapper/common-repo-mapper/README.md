# common-repo-mapper

掃描指定資料夾路徑，列出各路徑下的專案目錄，產生 `RepositoryMapping.md` 對照表。

---

## 使用方式

在 Copilot CLI 中說：

```
掃描這些路徑，產生 RepositoryMapping.md：
C:\91APP
D:\Code\Service
D:\Code\Console
```

或更新現有對照表：

```
重新掃描這些路徑，更新 RepositoryMapping.md
```

---

## 輸出格式

每個根目錄為一個區段，內含 Markdown 表格：

```markdown
## C:\91APP

| 專案名稱 | 路徑 |
|---|---|
| Nine1.Shopping | `C:\91APP\Nine1.Shopping` |
| NineYi.ERP | `C:\91APP\NineYi.ERP` |

---

## D:\Code\Service

| 專案名稱 | 路徑 |
|---|---|
| Nine1.Cart | `D:\Code\Service\Nine1.Cart` |
```

---

## 排除規則

| 規則 | 範例 |
|---|---|
| 以 `.` 開頭的目錄 | `.nuget`、`.git` |
| 以 `-worktrees` 結尾的目錄 | `NineYi.Sms-worktrees` |

---

## 安裝

```powershell
# 建立 Symbolic Link
$skillSrc = "D:\Code\Other\Nine1.Instructions\src\.github\skills\b2e\common-repo-mapper"
$skillDst = "$env:USERPROFILE\.copilot\skills\common-repo-mapper"
New-Item -ItemType SymbolicLink -Path $skillDst -Target $skillSrc -Force
```
