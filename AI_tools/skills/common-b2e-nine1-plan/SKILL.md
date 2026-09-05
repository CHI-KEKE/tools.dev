---
name: common-b2e-nine1-plan
description: >
  根據 Azure DevOps Work Item 生成完整的系統架構設計建議與實作計畫，產出 Arc42 格式
  的 ImplementPlan 並回寫至 VSTS。為 User Story to Tasks 流程的 Phase 2。
  完成後建議執行 `common-b2e-nine1-tasks` 進行任務拆解。
---

# common-b2e-nine1-plan

User Story to Tasks — **Phase 2：架構規劃**

Senior backend engineer perspective — generate concrete, implementable architecture design blueprints based on WI requirements and clarification results.

---

## Quick Start

1. Load `tf-work-item-context` skill → get WI Context (ImplementPlan validation not required)
2. Call `tf-clarifications-reader` → consolidate existing clarification records
3. Present Context summary ⏸
3.5. Load `references/skill-enrichment.md` → technical context enrichment + detect applicable implementation Skills (produces Detected Skill Mapping)
4. Load `references/design-blueprint.md` → generate core design (File Tree / DB / API) ⏸
5. Load `references/cross-cutting-concerns.md` → analyze Security / Perf / Maintainability
6. Generate Mermaid visualization diagrams (complex flows) ⏸
7. Load `references/implementplan-updater.md` → update VSTS Custom.ImplementPlan (includes Task 執行 Skills section if Detected Skill Mapping is non-empty)

---

## Shared Skill Dependencies

| Skill | Purpose | Required |
|-------|---------|:--------:|
| `tf-work-item-context` | WI loading (ImplementPlan may be empty) | ✅ |
| `tf-clarifications-reader` | Read existing clarification records | ✅ |

---

## Reference Map (load on demand)

| File | Load timing |
|------|-------------|
| `references/skill-enrichment.md` | After Step 3 confirmation, before Step 4 core design |
| `references/design-blueprint.md` | Before Step 4 core design generation |
| `references/cross-cutting-concerns.md` | Before Step 5 advanced analysis |
| `references/implementplan-updater.md` | Before Step 7 VSTS update |

---

## Execution Flow

### Phase 1: Context Collection (auto-execute)

#### Step 1 — Load WI Context
Call `tf-work-item-context` (`requireImplementPlan: false`).

#### Step 2 — Load Clarification Records
Call `tf-clarifications-reader`.

---

### Phase 2: Context Confirmation (awaits user confirmation)

#### Step 3 — Present Context Summary

```markdown
## 📋 Context Summary

### Work Item 資訊
...（WI 基本資訊）

### ImplementPlan 各段落狀態
...（✅/❌ 各 section）

### 釐清記錄摘要
...（最多 5 則，或「無釐清記錄」）

### 萃取的關鍵需求
- **功能需求：** ...
- **業務規則（若 WI 含條件邏輯）：**
  - 同時掃描 **`System.Description`** 與 **`Microsoft.VSTS.Common.AcceptanceCriteria`** 兩個欄位（兩者常分別記載不同的檢核項目，須整合、不得只看其中一個）
  - 偵測「若X則Y」「依X條件」「不同X有不同行為」「驗證規則」「允許/禁止」「顯示：」「不可」等字樣
  - 每條規則以「判斷條件 → 允許/禁止行為 → 逐字錯誤訊息（來源：Description/AC）」**單一格式逐條列出**，不得合併為一句話帶過、也不得分開重複描述
  - ⚠️ 若原文有指定對應的錯誤訊息文字（使用者可見的提示文案，常見於「顯示：『...』」「系統顯示...」等敘述），**該段訊息必須逐字引用，不得摘要、改寫或省略**；若原文未指定訊息文字，僅描述行為即可，不得自行杜撰
  - 此清單為 Step 4（驗證方法規格）與 Step 7（ImplementPlan）的**唯一依據**，後續步驟直接沿用、不重新掃描來源欄位
  - 若規則描述模糊或不完整，標記 ⚠️ 作為設計注意點
  - **若 Description 與 AC 皆未偵測到任何條件邏輯/驗證規則關鍵字**，明確輸出「本功能無明確業務規則或錯誤處理情境，略過此項」，**不得省略此 bullet 或留白**，也不得自行假設/杜撰規則
- **非功能需求：** ...
- **限制條件：** ...

---
✅ Context 摘要已完成。確認後進入核心架構設計？
```

**Wait for user confirmation**

---

### Phase 2.5: Technical Enrichment & Skill Detection (auto-execute after Step 3 confirmation)

#### Step 3.5 — Capability-Driven Technical Context Enrichment

**Trigger:** Executes automatically right after Step 3 is confirmed. No additional user confirmation needed.

Load `references/skill-enrichment.md` and execute both parts:
- **Part A** — gather the minimum technical evidence needed for design decisions (reusable components, naming/layering conventions, DI patterns, extension points, existing contract boundaries)
- **Part B** — dynamically scan `.github/skills/` for applicable implementation Skills, matching each Skill's trigger conditions against the confirmed requirements, and produce the **Detected Skill Mapping** (may be empty)

Store both outputs as internal input for Step 4 (design decisions) and Step 7 (ImplementPlan update). Do not display a separate user-facing section for this step unless it materially changes the design output.

**This step completes automatically and proceeds directly to Step 4.**

---

### Phase 3A: Core Design (awaits user confirmation)

#### Step 4 — Generate System Design Blueprint

Load `references/design-blueprint.md`, produce:
- New file list (with paths and responsibilities)
- Modified file list (with reasons for changes)
- Complete File Tree (marked [NEW] / [MODIFIED])
- DB changes (new tables, columns, indexes, migration strategy)
- Core code responsibilities and component interaction description

Use Step 3.5 findings to maximize reuse of existing components and align naming/layering with repository conventions before proposing new files.

**If Detected Skill Mapping (from Step 3.5) is non-empty**, append to the design presentation:

```markdown
### 🔧 建議套用的實作 Skills

| 適用 Skill | 觸發條件 | 適用 Task 範疇 |
|-----------|---------|---------------|
| `{skill-folder-name}` | {為何比對到此 Skill} | {哪些 Task 或產出物應呼叫此 Skill} |
```

If the mapping is empty, omit this section entirely — do not add placeholder text.

After presenting the design:

```markdown
✅ 核心設計藍圖完成。確認以上系統設計並繼續進階分析？
```

**Wait for user confirmation**

If the user requests modifications → re-plan and confirm again.

---

### Phase 3B: Advanced Analysis (awaits user confirmation)

#### Step 5 — Cross-cutting Concerns Analysis

Load `references/cross-cutting-concerns.md`, focus on:
- **Security**: authentication/authorization risks and mitigations
- **Performance**: potential bottlenecks and optimization strategies
- **Maintainability**: architecture layering, test coverage, documentation

#### Step 6 — Visualization Diagrams (conditional)

```
IF 業務流程涉及 3+ 系統元件 OR 有複雜分支 OR 需狀態機表示：
  → 生成 Mermaid 圖表（sequence diagram 或 flowchart）
ELSE：
  → 略過，標注「簡單 CRUD，無需視覺化圖表」
```

呈現進階分析後：

```markdown
✅ 進階分析完成。確認並更新 Azure DevOps ImplementPlan？
```

**Wait for user confirmation**

---

### Phase 4: Documentation Update (auto-execute after confirmation)

#### Step 7 — Update Custom.ImplementPlan

Load `references/implementplan-updater.md`, integrate design results into each Arc42 section, then **load and execute the `tf-work-item-writer` skill** to write the integrated content to `Custom.ImplementPlan` — follow the field-update instructions in `implementplan-updater.md` exactly. Do **not** call `update_work_item` directly.

After displaying update confirmation (with diff summary):

```markdown
🎯 **Phase 2 - Plan Complete — Ready for Task Breakdown**
建議執行 `common-b2e-nine1-tasks` skill 進行任務拆解。
```

---

## Execution Rules

- Pause points for user confirmation are detailed in each Step description; marked with ⏸ in Quick Start
- When uncertain, ask immediately — do not assume
- If user rejects design → re-plan and confirm again
- Complex logic must be visualized with Mermaid (simple CRUD may be skipped)
- All user-visible output uses **Traditional Chinese**; technical terms remain in English

## ⛔ MUST NOT

- Do not modify Work Item `Description` field
- Do not generate or modify any source code during this phase
- Do not use `[TBD]` placeholders in key sections (confirm with user first)
