# ImplementPlan Updater — Custom.ImplementPlan Update Rules

---

## Execution Preconditions

- Step 4 (core design) has been confirmed by the user
- Step 5-6 (advanced analysis) has been confirmed by the user
- The `Custom.ImplementPlan` field exists and is accessible

---

## Per-Section Integration Rules

| Arc42 Section | Update Source | Integration Strategy |
|---------------|---------|---------|
| 作法概述 (Approach Overview) | Step 4 core design approach + Step 5 design decisions | **Overwrite** (new design takes precedence; if the content contains check-item/error-message pairs verbatim-quoted from Description/AC in Step 3/4, **they must be preserved as-is — must not be summarized or rewritten during integration**) |
| 作法概述 附加：🔧 Task 執行 Skills | Step 3.5 Detected Skill Mapping (if non-empty) | **Append to the end of 作法概述** (if the Mapping is empty, skip — no placeholder text) |
| Container Diagram | — | **Keep existing** (recommend manual update) |
| Component Diagram | — | **Keep existing** (recommend manual update) |
| DB Schema | Step 4 (3.4) DB changes | **Overwrite** |
| API Spec | Step 4 (3.1-3.2) new/modified endpoint responsibilities | **Overwrite** |
| File Tree (new) | Step 4 (3.3) complete File Tree | **New Section** |
| Runtime View | Step 6 Mermaid diagrams (if any) | **Overwrite** (keep existing if none) |
| Non Functional Requirements | Step 5 cross-cutting concerns | **Overwrite** |
| Architecture Decisions (optional) | Step 4-5 important decisions (if any) | **New Section** (skip if none) |

---

## Task 執行 Skills Append Rule

**If Step 3.5's Detected Skill Mapping is non-empty**, append the following block to the **end** of the integrated 作法概述 content:

```markdown
## 🔧 Task 執行 Skills

以下 Skills 應在對應 Task 執行時由 Agent **明確載入並遵循**：

| Skill 名稱 | 套用時機 / 適用 Task |
|------------|-------------------|
| `{skill-folder-name}` | {觸發條件與適用的 Task 範疇} |
```

**If Detected Skill Mapping is empty, omit this block entirely** — do not add any placeholder text.

This block goes through the Markdown→HTML conversion together with 作法概述 and is written to VSTS, for reference by Phase 3 (`common-b2e-nine1-tasks`) when creating Task descriptions.

---

## Diff Comparison Logic

```python
if new_content == existing_content:
    skip_update()
    notify_user("No changes needed")
else:
    update_field()
    show_diff_summary()
```

---

## Executing the Update

> ⚠️ **Do not call `update_work_item` directly.** You must follow the steps below to ensure the Markdown is fully converted to HTML first — otherwise VSTS will display the raw markdown and line breaks will be lost.
>
> ⛔ **This is not a suggestion, it is a mandatory rule.** Even if the integrated content is long, contains multiple Mermaid diagrams, or large tables, you **must** fully run through `tf-work-item-writer`'s Step 1 (Markdown→HTML conversion) and Step 1-E (mandatory self-verification gate), confirming the converted content **contains no residual Markdown syntax** (`#` headings, ` ``` ` code fences, `**bold**`, `\| tables \|`, etc.) before proceeding to Step 2 write. **Do not skip this step for reasons such as "content is too long" or "get it working first, polish later."**

Load and execute `tf-work-item-writer/SKILL.md`, running the following steps in order:

1. **Step 1 (Markdown→HTML conversion)**: following the rules in `tf-work-item-writer/SKILL.md` Step 1, fully convert the integrated Markdown content (including the Task 執行 Skills block appended in Step 3.5) into HTML (including headings, lists, tables, bold, code blocks, Mermaid blocks, etc.).
2. **Step 1-E (mandatory self-verification gate)**: confirm the converted content contains no residual Markdown syntax; if it fails, go back to Step 1 and reconvert.
3. **Step 2 (Field Write)**: call `update_work_item` with the converted HTML content, writing to `Custom.ImplementPlan`:
   - `workItemId`: workItemId
   - `fieldUpdates`: `{"Custom.ImplementPlan": <HTML converted in Step 1>}`

---

## Confirmation Message Format

```markdown
✅ Custom.ImplementPlan 已更新

**Work Item：** #{workItemId}

**更新摘要：**
- ✅ 作法概述：以新設計方法覆蓋更新
- ⚠️ Container Diagram：保留既有（建議手動更新）
- ⚠️ Component Diagram：保留既有（建議手動更新）
- ✅ DB Schema：更新（{N} 個新增表格，{M} 個修改）
- ✅ API Spec：更新（新增/修改端點與職責）
- ✅ File Tree：新增（{N} 個新增，{M} 個修改）
- ✅ Runtime View：{更新 Mermaid 圖表 / 保留既有（簡單操作）}
- ✅ Non Functional Requirements：更新（Security / Performance / Maintainability）
- {✅/➖} Architecture Decisions：{新增決策表格 / 不適用}
- {✅/➖} 🔧 Task 執行 Skills：{已附加 N 個 Skill 對應（skill 名稱列表） / 未偵測到適用 Skill，略過此區塊}

---

⚠️ 需要手動更新的項目：
- 🔶 Container Diagram（系統境界圖）
- 🔶 Component Diagram（內部結構圖）

建議工具：C4-PlantUML、draw.io 或 Mermaid

---

**建議下一步：**
執行 `common-b2e-nine1-tasks` skill 進行任務拆解。
```

---

## If No Update Is Needed

```markdown
ℹ️ Custom.ImplementPlan 無需更新

**原因：** 新設計與既有計畫內容相同，無差異。

**建議行動：**
若預期有更新，請回至 Step 4-6 修改設計後重新執行。
否則，直接執行 `common-b2e-nine1-tasks` skill 進行任務拆解。
```
