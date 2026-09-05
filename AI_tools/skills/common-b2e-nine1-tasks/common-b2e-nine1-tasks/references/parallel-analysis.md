# Parallel Analysis — Parallel Execution Analysis & Dependency Matrix

---

## [P] Marking Criteria (all 4 conditions must be satisfied)

1. **File independence**: no overlapping file paths with other parallel tasks
2. **Dependency independence**: no explicit or implicit execution-order dependency on other tasks in the same group (including reference, injection, implementation, inheritance, mapping, testing, or other consumption relationships)
3. **Shared contract/resource independence**: does not modify shared resources used by other tasks, including: DB Schema, config files, global state, shared interfaces, shared DTOs, base classes, shared helpers, DI registration
4. **Independent testability**: build, DI wiring, and unit tests can run independently, without depending on the output of other parallel tasks

---

## Mandatory Dependency Determination Criteria

**Producer-output dependency rule:**
- If Task A creates or modifies a service interface, Repository interface, DTO, Entity, API contract, event, DB Schema, shared config, base class, shared helper, or test fixture, and Task B uses or depends on these artifacts, then Task B must execute after Task A.
- If Task B cannot compile, complete DI wiring, run tests, or complete implementation before Task A's artifacts exist, then Task B and Task A cannot run in parallel.

**Keyword signals (when present, treat as a dependency signal — cannot mark `[P]`):**

> `depends on`, `requires`, `uses`, `injects`, `implements`, `extends`, `maps to`, `based on`, `shared`

**Even if file paths do not overlap, the above keywords must still be treated as dependency signals.**

**Dependency inference constraints:**
- Only infer dependency relationships from the following existing task sections: `工作說明`, `設計考量`, `關鍵實作重點`, `異動檔案`, `相依關係`
- **Do not** introduce new sections just for the sake of this analysis

**Dependency inference example:**
- Task A creates the `IPromotionService` interface
- Task B injects and uses `IPromotionService`
- → Task B **cannot** be marked `[P]` alongside Task A (it consumes the contract newly created by Task A)

---

## Execution Flow

### Step 1 — Build the Dependency Matrix

Build a dependency matrix containing **at least** these columns: `任務`, `依賴於`, `產出/修改的產出物`, `消費的產出物`, `阻塞原因`

| 任務 | 依賴於 | 產出/修改的產出物 | 消費的產出物 | 阻塞原因 |
|------|--------|-----------------|------------|---------|
| Task 1 | — | `IPromotionService`（新） | — | — |
| Task 2 | Task 1 | `PromotionService.cs`（新） | `IPromotionService` | 消費 Task 1 新建介面 |
| Task 3 | Task 1 | `ProductController.cs`（修改） | `IPromotionService` | 消費 Task 1 新建介面 |

Derive "artifacts produced/modified" and "artifacts consumed" from each task's existing sections, build a **producer-consumer matrix**, and confirm whether any task consumes a contract or artifact produced by another task.

### Step 2 — Validate Every [P] Task Pair

**Only mark a task `[P]` after confirming ALL of the following:**
1. No direct dependency
2. No transitive dependency
3. No producer-consumer contract relationship (within the same group)
4. No shared contract/resource conflict

**If any item fails → remove the [P] marker and regroup.**

### Step 3 — Define Execution Groups

```markdown
**Group 1（平行）：** [P] Task 1, [P] Task 2, [P] Task 4
**Group 2（Group 1 後）：** Task 3, Task 5
```

### Step 4 — Explain Each Task

For every task, explicitly state:
- `[P]` task → **the reason it is parallel-safe**
- non-`[P]` task → **the blocking reason (Blocked By)**

---

## Execution Mode Classification

| Mode | Applicable Case | Tag |
|------|---------|-----|
| Local (synchronous) | High complexity, prototyping, refactors requiring real-time supervision | None |
| Cloud (asynchronous) | New features, bug fixes, repetitive tasks (well-tested repos) | `Coding-Agent` |

---

## Task Title Format

- Sequential task: `1. 任務標題`
- Parallel task: `[P] 1. 任務標題`
