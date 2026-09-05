# Excel 欄位 → Skill 問題對照表

此文件說明原本 Excel 表單的各欄位如何對應到 `submit-review-rule` Skill 的問題。

---

## 欄位對照

| Excel 欄位 | 是否詢問 | 對應 | 備註 |
|-----------|---------|------|------|
| 系統 (repo) | ❌ 不詢問 | — | 由 Rule Title 描述即可；Repository metadata 由語言自動對應 |
| 自訂規則類型 | ✅ Q2 | 決定存放資料夾 | CustomRules / ExceptionRules / NMQRules / InformationSecurity / best-practices |
| Rule Title | ✅ Q3 | MD 文件標題 | 中英文皆可，AI 自動翻譯英文版 |
| Key | ❌ 不詢問 | Phase 2 自動分配 | 掃描 knowledge_base/ 所有 N*.md，取最大值 + 1 |
| Add KB | ❌ 不詢問 | — | 預設 READY（合併後手動加入 Dify） |
| Created At | ❌ 不詢問 | 今天日期自動填入 | YYYYMMDD 格式 |
| Severity | ✅ Q4 | MD metadata | BLOCKER / CRITICAL / MAJOR / MINOR / INFO |
| Language | ✅ Q5 | MD metadata + Repository 自動對應 | C# → csharpsquid |
| Description | ✅ Q6 | Why is this an issue? | 為什麼這是個問題、影響是什麼 |
| Code examples (Noncompliant) | ✅ Q7 | Noncompliant Code Example | 含 `// Noncompliant` 注解 |
| Compliant solution | ✅ Q8 | Compliant Solution | — |
| Documentation (Optional) | ✅ Q9 | Resources | PR/VSTS/Slides/Git hash 連結 |
| 提供人 | ✅ Q1 | Commit message | 記錄在 git commit 中 |
| 主管 | ❌ 不詢問 | — | 透過 GitLab MR Reviewer 機制處理 |

---

## Repository 自動對應規則

| Language | Repository (SonarQube) |
|----------|----------------------|
| C# | `csharpsquid` |
| JavaScript | `javascript` |
| TypeScript | `javascript` |
| Java | `java` |
| Python | `python` |
| 其他 | `[repository-name]`（需手動填寫）|

---

## Key 編號空間

所有規則類型共用同一個 N 編號空間。  
掃描 `knowledge_base/backend/` 所有子目錄的 `N*.md`（排除 `_中文.md`），取最大值 + 1。

目前已知分佈：
- `CustomRules/`：N00016 ~ N00055
- `NMQRules/`：N00021, N00024, N00028

> **注意**：N00001 ~ N00015 可能在其他系統（如 SonarQube 管理頁面），不在此 repo 中。

---

## 目前已知規則類型說明

| 類型 | 資料夾 | 說明 |
|------|-------|------|
| 通用規則 | `CustomRules/` | 跨系統通用的 C# / 前端規則 |
| ExceptionRules | `ExceptionRules/` | 例外處理相關規則 |
| InformationSecurity | `InformationSecurity/` | 資訊安全相關規則 |
| NMQRules | `NMQRules/` | NMQ（Message Queue）相關規則 |
| best-practices | `best-practices/` | 最佳實踐建議 |
