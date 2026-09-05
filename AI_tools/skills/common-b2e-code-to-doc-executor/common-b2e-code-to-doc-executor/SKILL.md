---
name: common-b2e-code-to-doc-executor
description: >
  偵測 PR 合併或 Work Item 狀態變為 Done 後，分析 git diff 與現有 Domain 設計文件（`.docs/B2E/domain-{名稱}/` 下 8 個 md 檔）、API Spec（`.docs/B2E/api-spec/`）與 repo code_base instruction（`.github/instructions/repo_code_base.instructions.md`），自動分類受影響的檔案與段落，產出草稿或標記「需人確認」項目，最終輸出同步報告。
  僅產出草稿，不直接寫入文件；任何實際寫入動作皆需開發者明確確認後才執行。
  請在以下任何情境優先觸發此 Skill：使用者說「幫我同步 SD 文件」、「PR 合併後更新 SD 文件」、「diff 對應的 SD 文件有哪些需要更新」、「SD 文件自動更新」、「domain-sync」、「幫我 review SD 有沒有要補的」、「這個 PR 的 SD 要改哪裡」、「code_base instruction 要不要更新」、「套件版本有升，instruction 要同步嗎」，即使使用者沒有明確說「domain-sync-executor」也應觸發。
---

# Domain Sync Executor Skill

當 PR 合併或 Work Item 完成後，自動比對 git diff 與現有 Domain 設計文件 / API Spec / repo code_base instruction，產出文件同步草稿，並輸出結構化的同步報告以供人工審核。

本 Skill 同步的三類文件：

- **API Spec**：`.docs/B2E/api-spec/{controller-name}.md`（由 `common-api-spec-creator` 產出）
- **Domain 設計文件**：`.docs/B2E/domain-{名稱}/` 底下 8 個 md 檔（`00-overview.md` ～ `08-business-flow.md`，由 `common-b2e-sys-design-doc-creator` 產出）
- **Repo Code Base Instruction**：`.github/instructions/repo_code_base.instructions.md`（由 `repo-code-base-generation.agent` 初次產生；記錄 Environment / Project Structure / Deployment Environments / 實作準則）

前兩類由 `common-b2e-domain-initialize` Agent 初始化建立。

Keep the main skill file concise. Load `assets/sync-report-template.md` when generating the final report.

---

## Quick Start

1. 確認 **必要輸入** 已具備（diff + 現有 Domain 文件 / API Spec / code_base instruction），缺一不可。
2. 執行 **Step 1**：分析 diff，分類變更（影響 domain / 影響 code_base / 純重構）。
3. 執行 **Step 2**：找出每個影響項目對應的 Domain 資料夾與檔案（8 個 md 之一）、API Spec 檔案、或 `repo_code_base.instructions.md`。
4. 執行 **Step 3**：決策草稿類型（直接草稿 / 需人確認 / 新段落候選 / 新檔案候選）。
5. 執行 **Step 4**：產出草稿（diff 格式 + 標註來源 / 信心程度）。
6. 執行 **Step 5**：輸出同步報告，格式參照 `assets/sync-report-template.md`。
7. 執行 **Step 6**：等待人工 Approve 後，依指示寫入對應檔案（檔案層級寫入、檔案內段落粒度修改）。

---

## Core Rules（Always Apply）

- **有 diff 才執行**：沒有提供 diff 絕對不可繼續，必須先請使用者補充。
- **只產草稿，不主動寫入**：所有修改草稿皆需人工確認後才能寫入。
- **檔案層級寫入**：寫入時以 8 份 md 檔 / API Spec 檔為最小單位，禁止全文覆蓋整個 Domain 資料夾。
- **不刪除既有段落**：刪除動作需明確人工授權，不可自行判定刪除。
- **有依據才標記**：每個草稿項目都需標註來源 commit / 對應程式碼檔案行號。
- **業務語意需人確認**：凡涉及業務邏輯改寫，必須標記「需人確認」，不可自行決定。

---

## 絕對禁止事項（Always Enforce）

| 禁止 | 原因 |
|---|---|
| 直接 Write 整份 Domain 文件或整個 `domain-{名稱}/` 資料夾 | 防止 AI 誤覆蓋既有內容 |
| 自動寫入「需人確認」的段落 | 業務語意不能由 AI 單獨決定 |
| 刪除既有段落或既有 md 檔 | 需明確人工授權 |
| 在沒有 diff input 的情況下執行 | 避免空跑產生誤判 |

---

## 前置條件（Pre-flight）

**必要輸入：**
- 觸發來源：PR merged 或 Work Item 狀態變更為 Done
- `git diff upstream/develop...upstream/master` 的變更清單（`--stat` 與 `--name-only`）；若使用者未指定分支，預設以 `upstream/develop` 為 base、`upstream/master` 為 target
- 現有 Domain 文件（`.docs/B2E/domain-{名稱}/`）、API Spec（`.docs/B2E/api-spec/`）、repo code_base instruction（`.github/instructions/repo_code_base.instructions.md`）（或已知路徑）
- **額外需讀取**：若 diff 包含 `*.csproj`、`*.sln`、`Dockerfile`、`.gitlab-ci.yml`、`config/*`、`IServiceCollectionExtensions.cs` 等 code_base 相關檔案，必須同步讀取 `repo_code_base.instructions.md` 以比對

若缺少上述任一 input，**必須先請使用者補充，不可繼續執行**。

---

## 執行流程

### Step 1：分析 diff，分類變更

執行 `git diff --stat --name-only upstream/develop...upstream/master`（預設；使用者可指定其他分支覆蓋），將變更分類為：

| 類別 | 說明 | 影響文件 |
|---|---|---|
| 新增功能 / 新 API / 新 service | 新增檔案或新路由 | Domain 文件、API Spec |
| 修改行為 / schema 異動 / 參數變更 | 現有邏輯調整、欄位更名、型別變更 | Domain 文件、API Spec |
| 刪除功能 / 移除欄位 | 檔案刪除、API 移除、欄位 drop | Domain 文件、API Spec |
| **Framework / 套件版本升級** | `*.csproj` 內 `<TargetFramework>` 或 `<PackageReference>` 版號異動 | **code_base instruction** |
| **新增 / 移除專案** | `*.sln` 有新的 project 或移除 project、新的 Web API / Worker 專案資料夾 | **code_base instruction** |
| **部署 / CI 配置異動** | `Dockerfile`、`.gitlab-ci.yml`、`config/*` 變更 | **code_base instruction** |
| **DI 慣例 / 實作準則變更** | `IServiceCollectionExtensions.cs`、新增共通 base class、coding convention 變更 | **code_base instruction** |
| 純重構 | 僅影響程式碼結構，不影響對外行為、domain 描述或 code_base 說明 | 跳過 |

輸出：
- 「本次異動影響 domain 的項目清單」
- 「本次異動影響 code_base instruction 的項目清單」
- 「純重構項目（跳過）清單」

---

### Step 2：比對 Domain 文件檔案 / API Spec

**SD 文件查找規則：**

所有 SD 文件由 `common-b2e-domain-initialize` Agent 產出，位於：

- `.docs/B2E/api-spec/{controller-name}.md`
- `.docs/B2E/domain-{名稱}/` 底下：
  - `00-overview.md`
  - `01-c4-l1-system-context.md`
  - `02-c4-l2-container.md`
  - `03-db-schema.md`
  - `04-sequence-diagram.md`
  - `05-api-list.md`
  - `06-event-queue.md`
  - `07-cross-app-relationship.md`
  - `08-business-flow.md`

**推斷步驟：**

1. 從異動檔案路徑中提取 domain / module 名稱（例如 `src/Services/MemberService.cs` → `Member`）
2. 在 `.docs/B2E/` 底下搜尋 `domain-{名稱}/` 資料夾（大小寫不敏感）
3. 根據 diff 類型對應到 **8 份 md 檔之一**（對應規則見下表）
4. 若異動涉及 Controller / Worker，一併檢查 `.docs/B2E/api-spec/` 是否有對應 spec
5. 若找到多份候選資料夾，列出清單請使用者確認對應關係

**diff 類型 → 目標檔案對應表：**

| diff 類型 | 對應檔案 |
|---|---|
| DB schema / Migration / Model 欄位 | `03-db-schema.md` |
| 新增 / 修改 API 路由、參數、回傳 | `05-api-list.md` + `.docs/B2E/api-spec/{controller}.md` |
| Service / Handler 流程邏輯 | `04-sequence-diagram.md`、`08-business-flow.md` |
| Event / Queue / Message handler | `06-event-queue.md` |
| 跨 App / 外部系統整合 | `07-cross-app-relationship.md` |
| 新增 Container / 服務部署 | `02-c4-l2-container.md` |
| Domain 範圍 / 業務對象擴充 | `00-overview.md`、`01-c4-l1-system-context.md` |
| **`*.csproj` `<TargetFramework>` 升級** | `repo_code_base.instructions.md` → `# Environment` → `Framework` |
| **`*.csproj` `<PackageReference>` 版號異動** | `repo_code_base.instructions.md` → `# Environment` → `Packages` |
| **`*.sln` 新增 / 移除 project、新資料夾 `Web/`、`Worker/`** | `repo_code_base.instructions.md` → `# Project Structure` |
| **`Dockerfile` 基底映像 / 執行環境變更** | `repo_code_base.instructions.md` → `# Deployment Environments` → `Docker Container` |
| **`.gitlab-ci.yml` stage、分支策略變更** | `repo_code_base.instructions.md` → `# Deployment Environments` → `CI/CD` |
| **`config/*` 設定檔新增 / 刪除** | `repo_code_base.instructions.md` → `# Deployment Environments` → `配置管理` |
| **`IServiceCollectionExtensions.cs` 註冊慣例變更** | `repo_code_base.instructions.md` → `# 實作需求任務時必須遵守以下準則` |
| **Coding convention / 單元測試慣例變更**（例如改用其他 mocking 套件） | `repo_code_base.instructions.md` → `# 實作需求任務時必須遵守以下準則` |

對每一個「影響 SD 文件 / code_base instruction 的項目」：

- **找到對應檔案與段落** → 進入 Step 3 判斷
- **對應檔案存在但無對應段落** → 標記為「新段落候選」→ 進入 Step 4
- **`domain-{名稱}/` 資料夾或 API Spec 檔案完全不存在** → 標記為「新文件候選」→ 進入 Step 4（委派建立）
- **`repo_code_base.instructions.md` 完全不存在** → 標記為「需先執行 `repo-code-base-generation.agent`」→ 進入 Step 4（委派建立）

---

### Step 3：決策 — 直接草稿 vs 需人確認

**直接產出草稿（不需問）：**
- 欄位名稱異動（rename / add / drop）
- API 路徑、參數型別更新
- 版本號、計數、路徑更新
- 明確的 schema 變更對應

**標記「需人確認」：**
- 涉及業務邏輯描述的改寫（影響範圍 > 5 行）
- 異動原因不明確，diff 看不出意圖
- 刪除既有段落或既有 md 檔內容
- 與其他 md 檔有關聯性影響（例如同時影響 `04-sequence-diagram.md` 與 `08-business-flow.md`）

---

### Step 4：產出草稿

**對每個「直接草稿」項目，使用 unified diff 格式輸出：**

```
§ .docs/B2E/domain-Member/03-db-schema.md — MemberTier 欄位  [信心程度: High]
來源：commit abc1234 / src/Models/Member.cs#L42

- GoldTier = 2
+ GoldTier = 2
+ PlatinumTier = 3

說明：新增 PlatinumTier 等級，對應 PR #512 的 MemberTier enum 擴充。
```

**對每個「需人確認」項目：**

```
§ .docs/B2E/domain-Member/04-sequence-diagram.md — HamiPoint 綁定流程  [需人確認]
RECOMMENDATION：PR diff 顯示 BindingService 中 binding 邏輯有重大重寫，
但 diff 未說明業務意圖（重試策略改變？還是流程移除？），
建議開發者確認後再更新此檔案中的 HamiPoint 綁定流程段落描述。

現有文件內容：
  「使用者完成 OTP 驗證後，系統自動建立 HamiPoint binding...」
```

**對每個「新段落候選」：**

```
§ .docs/B2E/domain-Member/00-overview.md — CRM MemberTierExclude  [新段落候選]
根據推斷：src/Services/CrmService.cs 新增 ExcludeFromTierCalc flag

建議新增段落草稿：
## MemberTierExclude 排除機制
某些特殊會員身份（如員工帳號、測試帳號）可設定 ExcludeFromTierCalc = true，
該會員不納入等級計算與等級升降通知。
```

**對每個「新文件候選」（整個 `domain-{名稱}/` 資料夾或 API Spec 檔案不存在）：**

> 暫停自動流程，告知使用者：「偵測到此範圍尚無對應 Domain 文件，將委派 `common-b2e-domain-initialize` Agent 建立完整 Domain 文件（API Spec + 8 份 md 檔），請確認是否繼續？」
>
> 使用者確認後，呼叫 `common-b2e-domain-initialize` Agent，以現有 diff 影響範圍作為 Controller / Worker 範圍輸入。該 Agent 會依序呼叫 `common-api-spec-creator` 與 `common-b2e-sys-design-doc-creator`（Step 2A 盤點模式）完成建立。
> 委派完成後，以新建立的 Domain 文件為基礎，繼續 sync executor 的 Step 5 輸出同步報告。

**對 code_base instruction 的草稿範例：**

```
§ .github/instructions/repo_code_base.instructions.md — # Environment → Framework  [信心程度: High]
來源：commit def5678 / Web/Nine1.Offline.Order.Service.Web.Api/Nine1.Offline.Order.Service.Web.Api.csproj#L5

- **Framework**: .NET 6.0
+ **Framework**: .NET 8.0

說明：csproj `<TargetFramework>` 由 `net6.0` 升級至 `net8.0`，同步更新 instruction。
```

```
§ .github/instructions/repo_code_base.instructions.md — # Environment → Packages → Testing  [信心程度: High]
來源：commit def5678 / Test/*.Tests.csproj

- xUnit v2.4.1
+ xUnit v2.9.0
- NSubstitute v4.2.1
+ NSubstitute v5.1.0
```

```
§ .github/instructions/repo_code_base.instructions.md — # Project Structure → Web API  [新段落候選 / 需人確認]
來源：commit def5678 / Web/Nine1.Offline.Order.Worker/ （新資料夾）

建議新增條目：
- **Worker**:
  - `Web/Nine1.Offline.Order.Worker` - 訂單背景工作服務
```

**對「`repo_code_base.instructions.md` 不存在」的情境：**

> 暫停自動流程，告知使用者：「偵測到此 repo 尚無 `repo_code_base.instructions.md`，code_base 層級的同步無法進行。建議先執行 `repo-code-base-generation.agent` 初次掃描 `.sln` / `.csproj` 產生 instruction 檔，請確認是否繼續？」
>
> 使用者確認後，呼叫 `repo-code-base-generation.agent`。完成後以新建立的 instruction 為基礎，繼續 sync executor 的 Step 5。

---

### Step 5：輸出同步報告

載入 `assets/sync-report-template.md` 作為報告格式範本，產出最終同步報告。

---

### Step 6：等待人工 Approve 後寫入

```
開發者 review 草稿
  ↓
確認 → 寫入對應 md 檔（指定段落，禁止全檔覆蓋）
拒絕 → 記錄原因，保留原文不動
部分接受 → 只寫入被確認的段落
```

**寫入規則（確認後才執行）：**
- 操作單位為「8 份 md 檔之一 / 單一 API Spec 檔」內的指定段落，不可全檔覆蓋
- 每次寫入前先 `read` 目標檔案的目標段落確認內容仍一致
- 已確認草稿的信心程度標記需一併移除後寫入
- 同一次同步若影響多個 md 檔，需逐檔 read / 逐檔寫入，避免跨檔誤覆蓋

---

## Assets

| 檔案 | 用途 |
|------|------|
| `assets/sync-report-template.md` | Step 5 同步報告的輸出格式範本 |

---

## 相關 Agent / Skill

- `common-b2e-domain-initialize`（Agent）— 初始化整個 Domain 文件（API Spec + 8 份 md 檔）
- `common-api-spec-creator`（Agent）— API Spec 文件建立
- `common-b2e-sys-design-doc-creator`（Skill）— Domain 設計文件建立（Step 2A 盤點模式）
- `repo-code-base-generation.agent`（Agent）— 初次掃描 `.sln` / `.csproj` 產生 `repo_code_base.instructions.md`
