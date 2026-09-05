---
name: common-b2e-nine1-tasks
description: >
  將 Azure DevOps Work Item 拆解為可執行的 Tasks，分析平行執行可能性，驗證拆解完整性，
  在 VSTS 建立 Task，並生成任務進度追蹤表。為 User Story to Tasks 流程的 Phase 3。
---

# common-b2e-nine1-tasks

User Story to Tasks — **Phase 3：任務拆解與建立**

Senior backend engineer perspective — translate architecture design blueprints into assignable atomic tasks and identify parallel execution opportunities.

---

## Quick Start

1. Load `tf-work-item-context` skill → get WI Context
2. Call `tf-clarifications-reader` → consolidate clarification records
3. Validate ImplementPlan completeness ⏸
4. Load `references/task-breakdown.md` → generate task list *(optional pre-gate: `common-b2e-task-scope-gate`)*
5. Load `references/parallel-analysis.md` → parallel execution analysis
6. Present complete task breakdown ⏸
7. Load `references/task-validation.md` → 7-dimension validation ⏸ (when Warnings exist)
8. Confirm task granularity (A/B/C) ⏸ *(optional post-gate: `common-b2e-task-scope-gate`)*
9. Confirm VSTS creation parameters (Project / Area Path / Iteration Path) ⏸
10. Load `references/task-creation.md` → create Tasks
11. Generate task progress tracking table and write back to VSTS
12. Run AI validation (trigger validation Script)

---

## Shared Skill Dependencies

| Skill | Purpose | Required |
|-------|---------|:--------:|
| `tf-work-item-context` | WI loading and validation | ✅ |
| `tf-clarifications-reader` | Read existing clarification records | ✅ |
| `common-b2e-task-scope-gate` | Advisory merge/split scope judgment with normalized output | Optional |

---

## Reference Map (load on demand)

| File | Load timing |
|------|-------------|
| `references/task-breakdown.md` | Before Step 4 task list generation |
| `references/parallel-analysis.md` | Before Step 5 parallel analysis |
| `references/task-validation.md` | Before Step 7 validation |
| `references/task-creation.md` | Before Step 10 task creation |

---

## Execution Flow

### Step 1-2 — Load Context (auto-execute)

Call `tf-work-item-context` and `tf-clarifications-reader`.

---

### Step 3 — Validate ImplementPlan Completeness (awaits confirmation)

呈現各 section 填寫狀態：

```markdown
## 📋 ImplementPlan 完整性確認

- ✅/❌ 作法概述
- ✅/❌ DB Schema
- ✅/❌ API Spec
...
```

**If all sections are empty → stop, prompt user to run `common-b2e-nine1-plan` first.**

**If content exists → ask:** "ImplementPlan 已確認，開始任務拆解？"

**Wait for user confirmation**

---

### Step 4 — Generate Task List

Load `references/task-breakdown.md`, generate tasks following these principles:
- Each task 2-4 hours of work
- Each task affects 3-8 files
- Each task must be independently testable

#### Step 4.A — Optional Pre-Gate (Advisory Only)

Optionally load and run `common-b2e-task-scope-gate` with normalized input built from:
- `ImplementPlan`
- Clarifications summary
- Draft task list from Step 4

Use the gate output as advisory evidence only:
- `decision`
- `score`
- `matched_rules[]`
- `risk_flags[]`
- `evidence[]`
- `overrides`

Do not auto-merge or auto-split tasks from this step.

---

### Step 5 — Parallel Execution Analysis

Load `references/parallel-analysis.md`, use the 4-condition Framework to evaluate which tasks can run in parallel:
- Derive outputs and inputs from each task description generated in Step 4, build a **producer-consumer matrix**
- Build a dependency matrix (columns: task, depends on, produced/modified outputs, consumed outputs, blocking reason)
- Only mark `[P]` after confirming no direct dependency, no transitive dependency, no producer-consumer contract, and no shared resource conflict

---

### Step 6 — Present Complete Breakdown (awaits confirmation)

```markdown
✅ 任務拆解包含 {N} 個任務，{M} 個可平行執行 [P]。確認或修改？
```

**Wait for user confirmation**

---

### Step 7 — 7-Dimension Validation

Load `references/task-validation.md`, run the full validation report.

- **If Critical Issues exist → STOP, return to Step 4 and re-plan**
- **If only Warnings exist → present options to user, wait for user confirmation**

**Wait for user confirmation (Warnings scenario)**

---

### Step 8 — Confirm Task Granularity and Creation Parameters

#### 8.1 Confirm Task Granularity (awaits confirmation)

Before creating any Tasks, ask the RD:

```
目前共規劃 [N] 張 Task，請確認建立方式：

(A) 分開建立 [N] 張（維持目前規劃）
(B) 合併為 1 張 Task（請說明合併後的標題）
(C) 部分合併（請說明哪些要合併）
```

**Wait for user confirmation**

#### 8.1.A — Optional Post-Gate (Advisory Only)

After user confirms A/B/C granularity, optionally run `common-b2e-task-scope-gate` again on the **confirmed** granularity result.

Rules:
- Keep A/B/C decision ownership with user confirmation.
- Gate output cannot override or skip Step 8.2.
- If gate returns `manual_review`, surface the risk in chat but continue the flow per user-confirmed option.

#### 8.2 Confirm VSTS Creation Parameters (awaits confirmation)

Confirm: `Project`, `Area Path`, `Iteration Path`

```markdown
✅ 確認建立參數：Project: `{name}`, Area: `{path}`, Iteration: `{path}`？
```

**Wait for user confirmation**

---

### Step 10 — Create Tasks

Load `references/task-creation.md`, use `create_work_item` MCP Tool to create all Tasks.

**Before creating each Task:** apply the `tf-work-item-writer` Step 1 conversion rules (Step 1-A → 1-B → 1-C → 1-D) to convert the task description content to HTML. Pass the resulting HTML as the `description` parameter — do **not** pass raw Markdown.

**Tags (required for each Task):** `Task-待檢核`, `B2E-Implement`, `ParallelGroup-N` (when applicable), `Coding-Agent` (Cloud Execution)

**⚠️ No-Dedup Rule:** Create **all** Tasks listed in Step 4.3, regardless of whether child Tasks already exist under the Work Item. Do not skip, merge, or deduplicate due to similar titles or Active/In-Progress status.

**Key rule: Use the exact content confirmed in Step 6 — do not regenerate or rewrite.**

---

### Step 11 — Generate Progress Tracking Table

Generate a Task Progress Tracking Table and **load and execute the `tf-work-item-writer` skill** to write it back to the WI `Custom.TaskProgress` field — follow the progress tracking write-back instructions in `references/task-creation.md` exactly. Do **not** call `update_work_item` directly. (**This step must not be skipped**)

---

### Step 12 — Trigger AI Validation

Execute the validation Script using PowerShell tool:

```powershell
.\.github\ps\Invoke-TaskAIVerification.ps1 -TaskIds {task_ids}
```

**Script details:**
- Location: `.github\ps\Invoke-TaskAIVerification.ps1`
- Execution mode: Fire and Forget (parallel background job)
- Results: published to Azure DevOps Discussion within 1-3 minutes

**Troubleshooting:**

| Issue | Solution |
|-------|---------|
| Script not found | `Test-Path .\.github\ps\Invoke-TaskAIVerification.ps1` |
| Execution policy error | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Network error | Verify `https://dify.91app.biz` is accessible |

**Next steps:**
1. Wait 1-3 minutes to see results
2. Check AI validation results in Azure DevOps Discussion
3. Address issues based on AI feedback
4. To update the task progress table, return to Step 11

**If an error occurs during execution, report immediately and wait for user instructions.**

---

## Execution Rules

- Pause points for user confirmation are detailed in each Step description; marked with ⏸ in Quick Start
- If Step 7 validation has Warnings → present options and wait for user decision; if Critical Issues → force return to Step 4
- When Step 7 validation has Critical Issues, must return to Step 4 and re-plan before continuing
- Step 11 (progress table) must not be skipped
- Step 10 task creation uses the original content confirmed in Step 6 — do not regenerate
- All user-visible output uses **Traditional Chinese**

## ⛔ MUST NOT

- Do not modify Work Item `Description` field
- Do not generate or modify any source code during this phase
- Do not skip Step 11 progress tracking table
- Do not regenerate or rewrite Step 6 confirmed task content in Step 10
- Do not skip or merge any task because child Tasks already exist under the WI (No-Dedup Rule)
