---
name: f2e-ado-writer
description: Unified ADO write operations for F2E pipeline — add comments, upload attachments, create work items. Enforces summary-only plan comments and duplicate attachment prevention.
allowed-tools:
  - mcp-azure-devops/add_work_item_comment
  - mcp-azure-devops/add_work_item_attachment
  - mcp-azure-devops/get_work_item_attachments
  - mcp-azure-devops/create_work_item
  - mcp-azure-devops/update_work_item
---

## Preconditions

- Work Item ID must be provided
- Azure DevOps MCP connection must be available
- For attachment uploads: local file must exist
- For task creation: Project, Area Path, Iteration Path must be confirmed by user

## Operations

### Op A — Add Comment

Call `add_work_item_comment` with:
- `workItemId`: the Work Item ID
- `text`: comment body in Markdown format

**Comment title formats by phase:**
| Phase | Title Format |
|-------|-------------|
| Clearify (Phase 1) | `📋 F2E Clarifications - YYYY-MM-DD` |
| Plan summary (Phase 2) | `📋 Frontend Final Implementation Plan - YYYY-MM-DD` |

**⚠️ Plan comment (Phase 2) rule:**  
Post **summary notification only** — never paste full `implement-plan.md` content.  
Body must be: `✅ implement-plan.md 已產出，請至 Attachment 查看`

### Op B — Upload Attachment (with duplicate check)

1. Call `get_work_item_attachments` for the Work Item
2. Check if a file with the **same filename** already exists in the attachment list
3. If **duplicate found** → skip upload; log: `"⏭️ Attachment '{filename}' already exists — skipped"`
4. If **no duplicate** → call `add_work_item_attachment` with the local file path

### Op C — Create Work Item (Task)

Call `create_work_item` with:
- `type`: `Task`
- `state`: `New`
- `project`, `areaPath`, `iterationPath`: from user-confirmed values (Step 6 of f2e-nine1-task)
- `parentId`: User Story ID or specified parent
- `tags`: `Task-待檢核` (always) + `ParallelGroup-N` (if parallel) + `Coding-Agent` (if Cloud Execution)
- `title`: `[F2E] N. Task title` or `[F2E][P] N. Task title` for parallel tasks
- `description`: full task design content in Markdown; include Traceability (AC mapping)

**⚠️ Content Anchoring Rule:**  
Use exact content from task breakdown steps. No regeneration, summarizing, or paraphrasing.  
Only adjust formatting for Azure DevOps Markdown compatibility.

### Op D — Update Work Item Field

Call `update_work_item` with the specified field patch.  
Confirm field name with caller before executing.

## Hard Constraints

- **Plan comments are summary-only** — never post full implement-plan.md as comment body
- **Duplicate attachment check is mandatory** before every upload
- **Task tags must include `Task-待檢核`** — never omit
- **Content anchoring** — task descriptions must match exact task breakdown content
- Report all errors immediately and wait for caller guidance before retrying
