# Compatibility Gate — Technical Compatibility & Feasibility Gate

---

## Trigger Conditions

**Activate** the compatibility scan when the Work Item description or Implement Plan mentions any of the following:

| Trigger Type | Example Keywords |
|---------|-----------|
| Package / framework version upgrade | .NET 升版、NuGet 升級、SDK 版本異動 |
| Third-party API / SDK integration | 新服務串接、API 版本切換 |
| Cross-service / cross-system dependency | 新增上下游依賴、Service Bus、Event Grid |
| New technology introduction | 新資料庫類型、Queue、Cache、新 Protocol |
| Breaking change related | Migration、棄用 API、Schema 異動 |

**If the WI does not meet any trigger condition → skip directly, continue to Step 2 ambiguity scan.**

---

## Status Definitions

| Status | Definition | Gate Behavior |
|------|------|:--------:|
| ✅ Compatible | Official documentation explicitly supports it, no breaking change | Continue |
| ⚠️ Needs Evidence | Technically feasible, but lacks official supporting evidence | Continue, flag risk |
| 🔍 Unverified | Existing information is insufficient to confirm compatibility | Soft block, requires user confirmation |
| ❌ Incompatible | Official documentation explicitly does not support it | Hard block |

---

## Official Evidence Standard

### ✅ Accepted Sources

- Official Release Notes / Changelog (with version number)
- Official Migration Guide (official repo or documentation site)
- Official API Documentation (with version marker)
- Issues / PRs on the official GitHub repo (marked as official maintainer)
- Official Breaking Change announcement / Deprecation Notice

### ❌ Unaccepted Sources

- StackOverflow Q&A
- Unofficial blogs, technical community articles
- Word of mouth, team's past experience (can be supplementary, but not the sole basis)
- 91APP internal system integration → **use PoC results or Tech Lead confirmation document instead**

> **91APP exception rule:** For internal services (HamiPoint, PMIC, NMQ, etc.), an "internal API Spec document" or "Tech Lead written confirmation" replaces official documentation.

---

## Scan Items

After identifying the technical compatibility points in the WI, evaluate each one:

### 1. Version Compatibility
- Is the target version compatible with the existing technology stack (.NET Framework / .NET 6+, SQL Server version)?
- Are there any known breaking changes?
- Does the official source provide a migration path?

### 2. API / Protocol Compatibility
- Has the third-party API version been confirmed (major version)?
- Is the authentication method compatible with the existing auth architecture (OAuth 2.0, API Key, JWT)?
- Are there breaking changes in the Response / Request format?

### 3. Package Dependency Compatibility
- Does the new dependency conflict with existing package versions (NuGet dependency tree)?
- Is the commercial license compatible with 91APP's licensing policy?
- Have runtime environment constraints been confirmed (Windows-only, Linux container, etc.)?

---

## Gate Behavior

### ❌ Incompatible — Hard Block

Terminate the flow, output a blocking message:

```markdown
## 🚫 技術相容性閘門：硬性阻擋

偵測到不相容技術決策，**必須解決後才能繼續** common-b2e-nine1-clarify 流程。

| 技術點 | 狀態 | 官方依據 | 問題說明 |
|--------|------|---------|---------|
| {技術點} | ❌ Incompatible | {連結或說明} | {具體衝突} |

**解決路徑（擇一）：**
1. 修改技術方案，改用相容版本或替代技術
2. 提供官方文件證明此配置可行（請貼連結）

**common-b2e-nine1-clarify 流程在問題解決前暫停。**
```

---

### 🔍 Unverified — Soft Block

Pause and wait for the user to choose, **do not force termination**:

```markdown
## ⚠️ 技術相容性閘門：需確認

下列技術點目前無法確認相容性，請選擇處理方式：

| 技術點 | 狀態 | 說明 |
|--------|------|------|
| {技術點} | 🔍 Unverified | {說明} |

**請選擇：**
- **[A]** 提供官方文件連結或內部 PoC 結果
- **[B]** 已本地驗證，承擔風險繼續（將標記於最終報告）
- **[C]** 採用降級方案：{建議替代技術}

請回覆 A / B / C 後繼續。
```

**Processing logic:**
- `[A]` → After the user provides evidence, status is upgraded to Compatible or Needs Evidence, continue
- `[B]` → Status recorded as "Unverified (user acknowledged)", continue, flag risk in the final report
- `[C]` → Record the fallback decision, status recorded as "Compatible (fallback approach)", continue

---

### ⚠️ Needs Evidence — Flag and Continue

Does not block the flow, but is recorded as a pending risk item to be integrated into the final summary.

---

## Output Format (integrated into final summary)

```markdown
### 🔒 技術相容性閘門

| 技術點 | 狀態 | 官方依據 | 備註 |
|--------|------|---------|------|
| {技術點 1} | ✅ Compatible | {連結} | - |
| {技術點 2} | ⚠️ Needs Evidence | 尚未提供 | 建議 Phase 2 前補充 PoC |
| {技術點 3} | 🔍 Unverified → B（使用者知悉） | 無 | 風險已記錄，需 Phase 2 追蹤 |

**閘門結論：** {✅ 通過 / ⚠️ 通過（含風險）/ ❌ 阻擋}

**建議行動：**
- **{技術點}（⚠️）**：Phase 2 開始前補充官方 migration guide 連結
```

---

## Conditions That Do NOT Trigger the Compatibility Scan

Skip the gate in the following cases, to avoid excessive blocking:

- The WI is purely a business logic adjustment, with no technology stack changes
- The WI only involves UI/copy changes
- The WI is a bug fix to an existing system (no new dependencies)
- The technical point already explicitly states its official documentation source in the WI Description
