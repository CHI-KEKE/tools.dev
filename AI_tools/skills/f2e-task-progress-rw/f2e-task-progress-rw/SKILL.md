---
name: f2e-task-progress-rw
description: Read or write the task-progress.md tracking file for F2E pipeline. Local file only — no ADO calls.
allowed-tools:
  - read_file
  - write_file
  - run_command
---

## Preconditions

- Work Item ID must be provided
- Task data (IDs, titles, file paths) must come from **actual ADO creation results** — never from prior planning steps

## Workflow Steps

### Mode A — Write (after ADO task creation)

Write `.github/docs/{WORK_ITEM_ID}/task-progress.md` with the following format:

```markdown
## 📊 Task Progress Tracking - {YYYY-MM-DD}

| SeqNo | Task ID | Title | Files Changed |
|-------|---------|-------|---------------|
| 1 | #{actual_task_id} | {[P] N. Actual task title} | `path/to/file.tsx` [NEW]<br>`path/to/other.ts` [MODIFIED] |
| 2 | #{actual_task_id} | {N. Actual task title} | `path/to/component.tsx` [NEW] |

---

**Summary:**
- Total tasks: N | Parallel: N ([P]) | Sequential: N
- Total files affected: N (new: N, modified: N)
```

**Data source rules (no typos):**
- **Task ID**: copy exactly from ADO creation results (e.g. `#12345`)
- **Title**: copy exactly from ADO creation results; include `[P]` prefix if parallel
- **Files Changed**: from task list (Steps 3-4 of f2e-nine1-task); annotate `[NEW]` or `[MODIFIED]`
- **Date**: use actual date as `YYYY-MM-DD`; never use placeholders

### Mode B — Read (for progress check)

Run: `test -f .github/docs/{WORK_ITEM_ID}/task-progress.md && echo EXISTS || echo MISSING`

If EXISTS → read and return content.  
If MISSING → return: `"task-progress.md not found for Work Item {ID}"`

## Hard Constraints

- **No ADO calls** — this skill only reads/writes the local file
- **Data accuracy** — Task IDs and Titles must be copied verbatim from ADO results; never type from memory
- **Cannot be skipped** in f2e-nine1-task Phase 3 workflow
- **Create directory if needed**: `mkdir -p .github/docs/{WORK_ITEM_ID}` before writing
