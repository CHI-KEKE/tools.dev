---
name: f2e-implement-plan-loader
description: Load implement-plan.md for F2E pipeline. Checks local file first, falls back to ADO comment, blocks if neither exists.
allowed-tools:
  - read_file
  - run_command
  - mcp-azure-devops/get_work_item_comments
---

## Preconditions

- Work Item ID must be provided
- `.github/docs/{WORK_ITEM_ID}/` directory must be accessible (for local file check)

## Workflow Steps

### 1 — Check Local File

Run: `test -f .github/docs/{WORK_ITEM_ID}/implement-plan.md && echo EXISTS || echo MISSING`

### 2a — If EXISTS: Load Local File

Call `read_file` on `.github/docs/{WORK_ITEM_ID}/implement-plan.md`.

Return content to caller with source annotation: `(source: local file)`

### 2b — If MISSING: Fallback to ADO Comment

Call `get_work_item_comments` and search for comments titled:
- `📋 Frontend Final Implementation Plan - YYYY-MM-DD` (preferred)
- `📋 Frontend Implementation Plan - YYYY-MM-DD` (fallback)

If found → return content with source annotation: `(source: ADO comment – {title})`

### 3 — If Both Missing: BLOCK

**Stop** and report:
```
❌ implement-plan.md not found.
  - Local: .github/docs/{WORK_ITEM_ID}/implement-plan.md — NOT FOUND
  - ADO comment: No comment titled '📋 Frontend Final Implementation Plan - YYYY-MM-DD' found

Action required: Please run f2e-nine1-plan first to generate the implementation plan.
```

## Hard Constraints

- **Local file takes priority** over ADO comment — never skip the file check
- **Do not generate or infer** implement-plan content — only load what exists
- **Block and report** if neither source is available; never proceed with empty plan
