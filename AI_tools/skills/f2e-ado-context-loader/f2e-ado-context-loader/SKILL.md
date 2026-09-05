---
name: f2e-ado-context-loader
description: Load Azure DevOps Work Item context for F2E pipeline. Reads Description, Tags, State, Custom.FrontendImplementPlan, and F2E-titled comments. Ignores Task檢查結果 content.
allowed-tools:
  - mcp-azure-devops/get_work_item_details
  - mcp-azure-devops/get_work_item_comments
---

## Preconditions

- Work Item ID must be provided
- Azure DevOps MCP connection must be available

## Workflow Steps

### 1 — Fetch Work Item Details

Call `get_work_item_details` for the given Work Item ID. Extract:
- `id`, `title`, `state`, `tags`
- `description`
- `Custom.FrontendImplementPlan` — **CRITICAL**: always use this field; never confuse with `Custom.ImplementPlan` (backend only)

### 2 — Fetch Comments

Call `get_work_item_comments` and filter for F2E-relevant comment titles:
- `📋 F2E Clarifications - YYYY-MM-DD`
- `📋 Frontend Implementation Plan - YYYY-MM-DD`
- `📋 Frontend Final Implementation Plan - YYYY-MM-DD`

**When multiple comments match the same title prefix, use the one with the latest date.**

### 3 — Filter Out Irrelevant Content

**Ignore** all content under `Task檢查結果` headers in comments or description.  
Do NOT surface this content to the caller.

### 4 — Return Structured Context

Return to the caller:

```
Work Item:
  id: {ID}
  title: {Title}
  state: {State}
  tags: {Tags}
  description: {Description}

Custom.FrontendImplementPlan:
  {Content or "(empty)"}

F2E Clarifications (latest):
  {Content or "(none)"}

Frontend Implementation Plan (latest):
  {Content or "(none)"}

Frontend Final Implementation Plan (latest):
  {Content or "(none)"}
```

## Hard Constraints

- **Always use `Custom.FrontendImplementPlan`** — never `Custom.ImplementPlan`
- **Ignore `Task檢查結果`** — never return this content
- **F2E comments only** — do not surface backend/general comments as F2E context
- If Work Item is not found → report: `"Work Item {ID} not found or inaccessible"` and stop
