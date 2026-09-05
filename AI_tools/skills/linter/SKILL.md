---
name: linter
description: Deep knowledge of the 91APP Linter project — a .NET tool that runs AI code review via Dify bots on Bitbucket, GitLab, and GitHub PRs. Use this when the user asks to add rules, fix duplicate comments, converge Dify bots, debug AI review behavior, or understand how the Linter executes.
---

# Skill: 91APP Linter — AI Code Review System

**專案位置：** `C:\91APP\linter`  
**主要進入點：** `src/NineYi.Linter.Bitbucket/Program.cs`  
**目前分支：** `feature/VSTS00000-CustomFrontentRule-fix`（clean working tree，所有提案修改已 revert）

---

## 一、專案概述

Linter 是一個 .NET Console App，在 CI pipeline 觸發後：
1. 接收 PR 資訊（platform、repo name、PR ID、access token）
2. 找出對應的規則（Rules）
3. 呼叫 Dify AI Bot API，取得 code review 結果
4. 將 review comment 透過各平台 API 回寫到 PR

支援三個平台：**Bitbucket**、**GitLab**、**GitHub**

---

## 二、兩種執行機制

`Program.cs` 的 `RunCheckCode()` 有兩條獨立路徑，**兩者可能同時觸發**：

### 機制 1 — Attribute Scan（線上掃描）
```csharp
// lines 72-112
// 透過 Reflection 找所有 [RuleForRepo] attribute，比對 platform + repo name
var ruleTypes = Assembly.GetExecutingAssembly().GetTypes()
    .Where(t => t.GetCustomAttributes<RuleForRepoAttribute>().Any());
```
- 比對邏輯：`opts.Platform` == attribute 的 `Platform` **且** `opts.Name.ToLower()` matches attribute 的 `RepoName`
- `*` wildcard 代表全部 repo
- GitLab 規則都用此機制（`AiAssistantStandardForGitlabRule` 標記 `[RuleForRepo("*", Platform="GitLab")]`）

### 機制 2 — YAML Scan（repoMappingRuleSetting.yaml）
```yaml
# src/NineYi.Linter.Bitbucket/repoMappingRuleSetting.yaml
repository:
  - name: nineyi.webstore.mobilewebmall
    rules:
      - AiAssistantExceptionDifyRule
      - AiAssistantCodeMentorProDifyRule
```
- 主要用於 Bitbucket repo 的特定規則組合
- 目前 YAML 沒有 `platform` 欄位 → 潛在跨平台風險
- Dictionary key = `repo.Name`（全小寫）；lookup = `opts.Name.ToLower()`

---

## 三、Rule 類別繼承體系

### Bitbucket 路徑
```
BaseAiAssistantRule
  └─ BitbucketRule
       └─ (各 Bitbucket YAML rules)
```
- `BaseAiAssistantRule` **有** `GroupBy(m => m.Message)` message dedup（line 88-91）

### GitLab 路徑
```
GitLabAiAssistantRuleBase
  ├─ AiAssistantStandardForGitlabRule        ← [RuleForRepo("*", Platform="GitLab")]，覆寫 Check()
  ├─ AiAssistantStandardAndroidGitlabRule    ← [RuleForRepo("android_shopping", Platform="gitlab")]
  ├─ GitLabFrontendAiAssistantRuleBase
  │    ├─ AiAssistantAtmosUiDifyRule
  │    ├─ AiAssistantPaymentSdkDifyRule
  │    └─ ... (各 repo-specific frontend rules)
  └─ GitLabBackendAiAssistantRuleBase         ← 篩 .cs + .yaml，送全 diff
       ├─ GitLabCodeMentorProAiAssistantRule
       ├─ GitLabExceptionAiAssistantRule
       ├─ GitLabInfoSecurityAiAssistantRule
       └─ GitLabPerformanceAiAssistantRule
```
- `GitLabAiAssistantRuleBase` **沒有** message dedup（已知 bug）

### GitHub 路徑
```
GitHubAiAssistantRuleBase
  ├─ AiAssistantStandardForGithubRule
  ├─ GitHubFrontendAiAssistantRuleBase
  │    ├─ AiAssistantDcPlugDifyRule
  │    └─ AiAssistantNine1ServiceMWeb
  └─ GitHubBackendAiAssistantRuleBase
       ├─ GitHubCodeMentorProAiAssistantRule
       ├─ GitHubExceptionAiAssistantRule
       ├─ GitHubInfoSecurityAiAssistantRule
       └─ GitHubPerformanceAiAssistantRule
```
- `GitHubAiAssistantRuleBase` **沒有** message dedup（已知 bug）

---

## 四、.cs 檔案的 AI Review 流程（GitLab 為例）

一個 `.cs` 檔案在 GitLab PR 上**觸發 6 次 Dify 呼叫**：

| # | Bot 名稱 | Dify Key | 來源 |
|---|---------|----------|------|
| 1 | Standard/Backend | `app-ZiyaCPCjqiTaN8YEAsMTZU8e` | `AiAssistantStandardForGitlabRule` |
| 2 | CustomRuleBackend | `app-CzdjFhacdnhKZ9z3vGZdL9DL` | `AiAssistantStandardForGitlabRule` |
| 3 | CodeMentorPro | `app-JIUkO3aaOYo8fkcZrUFTMDrT` | `GitLabCodeMentorProAiAssistantRule` |
| 4 | Exception | `app-pl9UWW8u1JXJUjHl3u5oEzJ5` | `GitLabExceptionAiAssistantRule` |
| 5 | InfoSecurity | `app-P0lSijKmE4yOjzSDgmulKJk1` | `GitLabInfoSecurityAiAssistantRule` |
| 6 | Performance | `app-gqEaDhs6lVrHJFM1HI0GSPnu` | `GitLabPerformanceAiAssistantRule` |

每個 Bot 收到**完全相同的 diff**，因此很容易產生語意重複的 comment。

---

## 五、已確認的 Bug（未修復）

### Bug 1 — 缺少 Message Dedup（GitLab / GitHub）
- `BaseAiAssistantRule`（Bitbucket）有 `GroupBy(m => m.Message)` 去重
- `GitLabAiAssistantRuleBase` 與 `GitHubAiAssistantRuleBase` 缺少此邏輯
- **影響**：多個檔案 AI 回傳相同文字時，會重複發出 N 則相同 comment
- **修法**：在兩個 base class 的 `Check()` 方法末尾加入 GroupBy，參考 `BaseAiAssistantRule.cs` lines 88-91

### Bug 2 — CustomRuleFrontend Scope 擴散
- `AiAssistantStandardForGitlabRule.FilterAIAssistType()` 將 `.ts/.tsx` 映射到 `(Frontend, CustomRuleFrontend)` 兩個 type
- `CustomRuleFrontend`（`app-RXmYwAkwt4cO3XvWUB5MHJDJ`）原設計只給 Bitbucket mweb，但因此跑在**所有 GitLab repo 的 `.ts` 檔**
- **修法**：移除 `FilterAIAssistType()` 中 `.ts/.tsx` → `CustomRuleFrontend` 的 mapping（一行改動）

### Bug 3 — android_shopping 同一 Dify Key 被呼叫兩次
- `AiAssistantStandardForGitlabRule`（`*`）和 `AiAssistantStandardAndroidGitlabRule`（`android_shopping`）都對 `.ts` 呼叫 `FrontendStandard`（`app-8QE3RFleNCDBl42rQwyMFhif`）
- **修法**：移除 `AiAssistantStandardAndroidGitlabRule.FilterAIAssistType()` 中的 Frontend/CustomRuleFrontend mapping

### Bug 4 — YAML Scan 無 Platform 過濾
- `repoMappingRuleSetting.yaml` 無 `platform` 欄位
- 若 GitLab repo 名稱恰好與 Bitbucket YAML entry 相同，Bitbucket rules 會誤觸發在 GitLab PR

---

## 六、27 個 Dify Bot 完整清單

| Bot | Dify Key | 檔案類型 | 收斂群組 |
|-----|----------|---------|---------|
| Standard/Backend | `app-ZiyaCPCjqiTaN8YEAsMTZU8e` | `.cs` | backend_general |
| CustomRuleBackend | `app-CzdjFhacdnhKZ9z3vGZdL9DL` | `.cs` | backend_general |
| Exception | `app-pl9UWW8u1JXJUjHl3u5oEzJ5` | `.cs/.yaml` | backend_general |
| InfoSecurity | `app-P0lSijKmE4yOjzSDgmulKJk1` | `.cs/.yaml` | backend_general |
| CodeMentorPro | `app-JIUkO3aaOYo8fkcZrUFTMDrT` | `.cs/.yaml` | backend_general |
| Performance | `app-gqEaDhs6lVrHJFM1HI0GSPnu` | `.cs/.yaml` | backend_general |
| NMQ | `app-7tbgGnCQviTmuS0b3FLvvnFr` | `.cs` | backend_nmq（可選合入 backend_general） |
| FrontendStandard | `app-8QE3RFleNCDBl42rQwyMFhif` | `.ts/.tsx/.json/.cshtml/.html` | 保留 |
| CustomRuleFrontend | `app-RXmYwAkwt4cO3XvWUB5MHJDJ` | `.ts/.tsx/.json` | frontend_mweb |
| WebStoreFrontEnd | `app-rNOobH1pVE5whKiJcqT0syyQ` | `.ts/.tsx/.json` | frontend_mweb |
| SmsFrontEnd | `app-rhEbqbomvKZtoX2Bpr2vlM0p` | `.ts/.tsx/.json/.cshtml/.html` | 保留 |
| Quality (.py) | `app-6usIGhNM7aaMQ9HJWDmEObmc` | `.py` | python |
| CustomRuleQuality | `app-xKFRMOkPnJoPVZFnVPCdO3dP` | `.py` | python |
| PostgreSQL | `app-W83s8Gyrdp2H6bYO1hyWhxJS` | `.sql` | 保留 |
| DomainRuleQuality | `app-htfZPQfzq56Q77rXvLINdosE` | `.md (C\d+.md)` | 保留 |
| Android | `app-iQmh5ilJXf7z7kMcoU4Y5Yst` | `.java/.kt` | 保留 |
| Nine1ServiceMWeb | `app-1XDbzqO6vutzSg2bmm2ApXnh` | `.ts/.tsx/package.json` | 保留 |
| PaymentSdk | `app-5e9no4a42kioHl8rfV2u9c1K` | `.ts/.tsx/package.json` | 保留 |
| DcPlug | `app-dmSxYVtnoyUekUUaAHC9P5gt` | `.ts/.tsx/package.json` | 保留 |
| ProductToCart | `app-HFoml67eX7MkVWiO728NePPD` | `.ts/.tsx/package.json` | 保留 |
| AtmosUi | `app-VPCTqUDJTtrEXMh27odheoVS` | `.ts/.tsx/package.json` | atmos_ui |
| AtmosUiStyle | `app-kka34jEgfTL6lrMht3fv28qt` | `.ts/.tsx/package.json` | atmos_ui |
| AtmosUiIcon | `app-w9EdRUBpRd9uVGtmVwUY8ejV` | `.ts/.tsx/package.json` | atmos_ui |
| ThemeCoreFrontEnd | `app-VPj6fbZq6LO3uzDhzthIZ5VM` | `.ts/.tsx/package.json` | 保留 |
| Database | `app-VX2NYs4cLOP2q4g5Rz9NG5kg` | 特殊 | 保留 |
| SplitContent | `app-qlEl7JuGMCsBEdSxGaKAGlKv` | 特殊 | 保留 |
| TestCaseManagement | `app-F1tTQCjH2dNyCOhgp0J4XAv0` | 特殊 | 保留 |

---

## 七、Bot 收斂計畫摘要

詳細計畫：`doc/DifyBot-Convergence-Plan.md`

| 群組 | 現有 | 收斂後 | 優先度 |
|------|------|--------|-------|
| Backend General（Exception/InfoSecurity/CodeMentorPro/Performance/Standard/CustomRule） | 6 | 1 | 🔴 最高 |
| AtmosUI（atmos-ui / styles / icons） | 3 | 1 | 🟡 |
| mweb Frontend（CustomRuleFrontend + WebStoreFrontEnd） | 2 | 1 | 🟡 含 Bug Fix |
| Python（Quality + CustomRuleQuality） | 2 | 1 | 🟡 |
| NMQ（可選合入 Backend） | 1 | 0 | 🟢 |
| **總計** | **27** | **~18** | |

---

## 八、關鍵檔案速查

| 檔案 | 用途 |
|------|------|
| `src/NineYi.Linter.Bitbucket/Program.cs` | 主程式，兩種執行機制（Attribute Scan lines 72-112, YAML Scan lines 182-232） |
| `src/.../repoMappingRuleSetting.yaml` | YAML Scan 的 repo → rule 對應表（Bitbucket only） |
| `src/.../RepoRules/BaseAiAssistantRule.cs` | Bitbucket base，有 GroupBy dedup（line 88-91），是 GitLab/GitHub 的參考實作 |
| `src/.../RepoRules/GitLabAiAssistantRuleBase.cs` | GitLab base，缺 dedup，Bug 1 的位置 |
| `src/.../RepoRules/GitHubAiAssistantRuleBase.cs` | GitHub base，缺 dedup，Bug 1 的位置 |
| `src/.../RepoRules/AiAssistantStandardForGitlabRule.cs` | GitLab 萬用規則（`*`），`FilterAIAssistType()` 是 Bug 2/3 的位置 |
| `src/.../RepoRules/AiAssistantStandardAndroidGitlabRule.cs` | android_shopping 規則，Bug 3 的位置 |
| `src/.../RepoRules/GitLabBackendAiAssistantRuleBase.cs` | 4 個 dedicated backend rules 的 base，語意重複的根源 |
| `src/.../RepositoryMapping.cs` | YAML 反序列化 model，目前只有 `Name` + `Rules`，無 `Platform` 欄位（Bug 4） |
| `doc/DifyBot-Convergence-Plan.md` | Bot 收斂完整計畫文件 |
| `doc/CustomRuleFrontend-in-StandardGitlabRule-issue.md` | Bug 2（CustomRuleFrontend scope）說明文件 |

---

## 九、新增規則 SOP

### 在現有 Standard rule 增加新 Bot（最簡方式）
1. `AiAssistantStandardForGitlabRule.cs` → `GetAIKeyForType()` 加新的 `AIAssistType` case 與 Dify key
2. `FilterAIAssistType()` 在對應副檔名加入新的 type
3. 對應 GitHub：同步修改 `AiAssistantStandardForGithubRule.cs`

### 新增 Repo-Specific Rule（dedicated rule file）
1. 繼承 `GitLabAiAssistantRuleBase`（或對應 Frontend/Backend base）
2. 加 `[RuleForRepo("repo-name", Platform="GitLab")]` attribute
3. 覆寫 `DifyApiKey` property 填入 Dify key
4. 若為 YAML 方式：加到 `repoMappingRuleSetting.yaml` 的 repo rules 清單

### 常見陷阱
- GitLab/GitHub 新規則繼承 base class 後**不會自動有 dedup**，PR 中多個相同問題的檔案會發出重複 comment
- `FilterAIAssistType()` 回傳多個 type 代表同一 diff 呼叫多個 Bot，請確認不重疊
- `PushGitLabMessage` 中 `LineFrom == -1` 走 Discussions API；`LineFrom == 0 && LineTo == 0` 走 comment API；其他組合**會被 silently drop**
