---
name: tf-work-item-writer
description: >
  Tasking Flow 共用 Skill：格式化並寫入 Azure DevOps Work Item 內容。
  支援 Discussion 留言寫入、欄位更新（如 Custom.ImplementPlan）、或兩者混合。
  在寫入前統一將 Markdown 完整轉換為 HTML（標題、段落、清單、表格、粗體、程式碼等），確保 VSTS 渲染正確。
  處理寫入失敗的重試邏輯與錯誤回復策略，並回傳寫入確認。
  適用於所有需要將分析結果、釐清內容、架構設計或進度記錄寫回 VSTS 的場景。
---

# tf-work-item-writer

Tasking Flow shared Skill. Preprocesses and writes content to VSTS Work Item — either as a Discussion comment, field updates (e.g. `Custom.ImplementPlan`, `Custom.TaskProgress`), or both. Converts full Markdown to HTML before writing (headings, paragraphs, lists, tables, bold, code blocks) to ensure reliable VSTS rendering regardless of newline handling.

**Prerequisite:** At least one of `commentMarkdown`/`commentTitle` pair or `fieldUpdates` must be provided.

---

## Input

| Parameter | Required | Description |
|-----------|:--------:|-------------|
| `workItemId` | ✅ | Target Work Item ID |
| `commentTitle` | ❌ | Comment title (e.g. `📋 Clarifications - 2026-03-20`). Required when writing a comment. |
| `commentMarkdown` | ❌ | Markdown content for the comment body. Required when writing a comment. |
| `fieldUpdates` | ❌ | Dict of field name → Markdown content to update. e.g. `{"Custom.ImplementPlan": "..."}` |

**Write modes:**
- **Comment mode**: `commentTitle` + `commentMarkdown` both provided → write Discussion comment
- **Field mode**: `fieldUpdates` provided → update Work Item fields
- **Mixed mode**: both provided → write comment first, then update fields

---

## Step 1 — Format Preprocessing

Before any write operation, apply full Markdown→HTML conversion to all content being written (both `commentMarkdown` and each value in `fieldUpdates`).

**Exception:** If a content block already starts with an HTML tag (the block begins with `<`), treat it as already-HTML and preserve as-is without conversion.

Apply the following sub-steps in order:

### Step 1-A — Protect Code Blocks

Extract and replace with placeholders to prevent conversion:

- Fenced code block ` ```lang\n...\n``` ` → `{{CODE_N}}` (capture language and content)
- Mermaid block ` ```mermaid\n...\n``` ` → `{{MERMAID_N}}` (capture content)
- Inline code `` `code` `` → `{{INLINE_N}}` (capture content)

### Step 1-B — Convert Markdown Pipe Tables → `<table>`

Scan for Markdown pipe table syntax. A pipe table is detected when:
- A line starts and ends with `|`
- The following line is a separator row (contains only `|`, `-`, `:`, and spaces)

Conversion output format:
```html
<table><tr><th>Header1</th><th>Header2</th></tr><tr><td>Value1</td><td>Value2</td></tr></table>
```

Rules:
- Each `<tr>`, `<th>`, `<td>` stays on one line (no line breaks inside tags)
- Header row uses `<th>`, data rows use `<td>`
- Cell content containing newlines uses `<br>` within the tag

### Step 1-C — Convert Remaining Markdown → HTML

Convert all remaining Markdown syntax:

| Markdown | HTML Output |
|----------|-------------|
| `# Heading` | `<h1>Heading</h1>` |
| `## Heading` | `<h2>Heading</h2>` |
| `### Heading` / `#### Heading` / etc. | `<h3>` / `<h4>` / etc. |
| `**text**` | `<strong>text</strong>` |
| `*text*` | `<em>text</em>` |
| `- item` (unordered, including nested) | `<ul><li>item</li></ul>` |
| `1. item` (ordered, including nested) | `<ol><li>item</li></ol>` |
| `[text](url)` | `<a href="url">text</a>` |
| `---` (standalone line) | `<hr>` |
| Text block separated by blank lines | `<p>...</p>` |

**Paragraph rule:** A block of consecutive lines not matched by any other rule becomes a `<p>` element. Within a paragraph block, single newlines are replaced with a space (merged into one line).

### Step 1-D — Restore Code Blocks

Replace placeholders with HTML:

- `{{CODE_N}}` → `<pre><code class="language-X">...content (escape `<` as `&lt;`, `>` as `&gt;`)...</code></pre>`
- `{{MERMAID_N}}` → `<pre>...mermaid raw content...</pre>`
- `{{INLINE_N}}` → `<code>...inline raw content...</code>`

After preprocessing, proceed to Step 1-E.

---

## Step 1-E — Mandatory Self-Verification Gate

**This gate is NOT optional and MUST be executed for every write, regardless of content size or complexity.**

Before calling `add_work_item_comment` or `update_work_item`, scan the fully preprocessed content (after Step 1-D restoration) for any residual raw Markdown syntax. The write is **blocked** if any of the following patterns remain outside of restored `<pre>`/`<code>` blocks:

- Leading heading markers: lines starting with `#`, `##`, `###`, etc.
- Unconverted fenced code markers: literal ` ``` ` sequences (should have been replaced by `<pre><code>` in Step 1-D)
- Unconverted bold/italic markers: `**text**` or `*text*` still present as literal asterisks
- Unconverted pipe table syntax: lines matching `| ... | ... |` with a separator row of `-`/`:`/`|`
- Unconverted list markers: lines starting with `- ` or `1. ` that were not wrapped in `<ul>`/`<ol>`

**If any residual raw Markdown syntax is found:**
1. **STOP** — do not proceed to Step 2
2. Return to Step 1-A and redo the full Markdown→HTML conversion on the offending section
3. Re-run this verification gate before proceeding

**Do not rationalize skipping this gate** (e.g., "content is too long", "mermaid diagrams are fine as-is") — every field written to VSTS via this Skill MUST be fully converted HTML with zero raw Markdown syntax remaining.

Only after this gate passes, proceed to Step 2 using the converted HTML content.

---

## Step 2 — Execute Writes

Execute writes according to the active mode. In Mixed mode, always write comment first, then update fields.

### Comment Write

```
add_work_item_comment(id: workItemId, text: <preprocessed_comment_content>)
```

→ Success: record `comment_id` and `comment_url`, continue to field write (if Mixed mode) or go to Output.
→ Failure: go to Step 3A — Comment Write Failure Handling.

### Field Write

```
update_work_item(
    id: workItemId,
    fields: {
        "<field_name>": "<preprocessed_field_content>",
        ...  // repeat for each key in fieldUpdates
    }
)
```

→ Success: go to Output.
→ Failure: go to Step 3B — Field Write Failure Handling.

---

## Step 3A — Comment Write Failure Handling

Display the following message and wait for user selection:

```markdown
## ⚠️ VSTS 留言寫入失敗

**Work Item：** #{workItemId}
**標題：** {commentTitle}
**錯誤訊息：** {error_message}

**請選擇處理方式：**

| 選項 | 說明 |
|------|------|
| **[R] 重試** | 再次嘗試寫入（建議先確認網路連線） |
| **[M] 手動新增** | 複製下方內容，手動貼入 VSTS Discussion |
| **[C] 繼續執行** | 略過留言寫入，使用記憶體中的資料繼續 |

---

**留言內容（供手動複製）：**

{commentMarkdown}

---

**您的選擇（R / M / C）：**
```

**Execution logic:**
- `[R]`: Retry once → if failed again, return to this step
- `[M]`: Display comment content for copying; continue after user confirms
- `[C]`: Skip write, continue with warning marker `⚠️ 留言未寫入（已略過）`

---

## Step 3B — Field Write Failure Handling

Display the following message and wait for user selection:

```markdown
## ⚠️ VSTS 欄位更新失敗

**Work Item：** #{workItemId}
**欄位：** {field_name(s)}
**錯誤訊息：** {error_message}

**請選擇處理方式：**

| 選項 | 說明 |
|------|------|
| **[R] 重試** | 再次嘗試更新（建議先確認網路連線） |
| **[M] 手動更新** | 複製下方內容，手動貼入 VSTS 欄位 |
| **[C] 繼續執行** | 略過欄位更新，使用記憶體中的資料繼續 |

---

**欄位內容（供手動複製）：**

{fieldUpdates content per field}

---

**您的選擇（R / M / C）：**
```

**Execution logic:**
- `[R]`: Retry once → if failed again, return to this step
- `[M]`: Display field content for copying; continue after user confirms
- `[C]`: Skip update, continue with warning marker `⚠️ 欄位未更新（已略過）`

---

## Output: Success Confirmation

```markdown
✅ VSTS 寫入完成

**Work Item：** #{workItemId}
**寫入時間：** {YYYY-MM-DD HH:MM}

{如有留言寫入：}
**留言標題：** {commentTitle}
**留言 ID：** {comment_id}

{如有欄位更新：}
**更新欄位：** {field_name(s)}
```

---

## Error Handling Summary

| Situation | Behavior |
|-----------|---------|
| Comment write failure | Display [R/M/C] options, wait for user decision |
| Comment retry failure | Display [R/M/C] options again |
| Field write failure | Display [R/M/C] options, wait for user decision |
| Field retry failure | Display [R/M/C] options again |
| User selects [M] | Display full content, continue after confirmation |
| User selects [C] | Mark with `⚠️ 未寫入（已略過）`, continue flow |
