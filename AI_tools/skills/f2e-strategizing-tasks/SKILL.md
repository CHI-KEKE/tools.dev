---
name: f2e-strategizing-tasks
description: Break down frontend tasks and analyze parallel execution with explicit frontend-only scope boundaries; avoid backend invocation and backend implementation planning.
allowed-tools:
  - read_file
  - file_search
  - mcp_azuredevopsas_get_work_item
  - mcp_azuredevopsas_create_work_item
---

## Preconditions

- Work Item must be provided (Description, Acceptance Criteria, Custom.FrontendImplementPlan)
- `.github/docs/{WORK_ITEM_ID}/` directory must be accessible (for scanning figma-analysis files)
- F2E Clarifications complete (optional)
- `implement-plan.md` complete (optional)

**Input:**

- **Work Item**: Azure DevOps Work Item (Description, Acceptance Criteria, Custom.FrontendImplementPlan)
- **Clarifications**: Discussion comments titled `📋 F2E Clarifications - YYYY-MM-DD`
- **Implement Plan** (optional): `.github/docs/{WORK_ITEM_ID}/implement-plan.md` for scope and architecture alignment
- **Figma analysis docs** (optional): `.github/docs/{WORK_ITEM_ID}/figma-analysis-*.md` for mapping in §4.2 and filling each task's Figma Analysis Snippet

## Workflow Steps

**Output:**

- **Task list**: Each task includes full task design content (Context & Scope, Goals & Non-Goals, Work Description, Design Considerations, Figma Analysis Snippet, etc.)
- **Parallel markers and execution groups**: Tasks meeting all four [P] criteria marked as `[P]`; Execution Groups produced (e.g. Group 1 (Parallel): …; Group 2 (After Group 1): …)
- **Dependencies**: Task-to-task dependencies (Task ID mapping)
- **Traceability matrix**: Bidirectional mapping User Story AC ↔ Tasks and coverage status
- **Confirmation summary**: Full task breakdown for user confirmation before creating Azure DevOps work items

When breaking down work, follow **MVP** and **frontend development flow**:
- Each task must yield a testable, independently verifiable outcome
- Avoid grouping unrelated logic in the same task
- Adjust task complexity based on implementation constraints
- **Describe what is to be done; do not implement it**

### 1 Generate Initial Task List

#### 1.1 Task Grouping Strategy (F2E-oriented)

**Merge into a single task when:**
- Component + corresponding hooks/state → "UI & logic layer" (single feature block, 2–4 hours)
- Page + its sub-components + data fetching → "Feature implementation" (within same page)
- Same-domain list/form/filter work (doable in 2–4 hours)
- API type definitions + corresponding service/hook → "Data layer & API integration"

**Split into separate tasks when:**
- Different domains (e.g., product list vs. cart vs. checkout)
- Different expertise (e.g., complex forms vs. charts vs. performance tuning)
- Non-functional work (performance, accessibility, bundle, monitoring)
- E2E / integration tests (after feature completion)

**Task sizing criteria (all must be met):**

| Criterion | Target | Too small → merge | Too large → split |
|-----------|--------|--------------------|-------------------|
| **Dev time** | 2–4 hours | < 30 min | > 8 hours |
| **File impact** | 3–8 files | 1 file | > 10 files |
| **Functional unit** | Testable feature/screen | Single file or artifact | Multiple features |
| **Autonomy** | Single developer | N/A | Multiple teams |

**Example contrast:**

❌ **Overly fine (~10 tasks):** Create ProductCard → Create useProduct hook → Create ProductList → Create API service → Create types → ...  
✅ **Appropriate (~3 tasks):**
- [P] Build product list UI & data layer (ProductCard, ProductList, useProduct, API types + tests)
- [P] Build cart components & state (CartItem, CartSummary, useCart + tests)
- Wire product list & cart APIs and error handling (integration + tests)

---

#### 1.2 Frontend Development Flow Sequence (recommended order)

When breaking down tasks, prefer this frontend development flow (not mandatory; adjust as needed):

| Order | Phase | Content |
|-------|--------|---------|
| 1 | **Design System & UI Foundation** | Design Tokens, component library; base styling (CSS-in-JS, utilities); reusable UI components |
| 2 | **Static UI Implementation** | Component layout & styling, responsive, static content |
| 3 | **State Management Architecture** | State shape (stores, context, local state), data flow, persistence if needed |
| 4 | **API Integration** | API contracts & types, data fetching (SWR, React Query, etc.), loading/error states |
| 5 | **Interactive Flow Implementation** | Form validation & submit, routing & navigation, user interaction handlers |
| 6 | **Testing & Optimization** | Unit tests for components/hooks, integration tests, performance & monitoring |

If total tasks are many (e.g. 5+), group by domain: UI components, state management, API integration, testing.

---

#### 1.3 Task Design Document Elements

Each task must include:

| Section | Description |
|---------|-------------|
| **Context & Scope** | Business goal and technical context (page/feature scope); explicitly map to User Story AC where applicable |
| **Goals & Non-Goals** | What is in scope and what is explicitly out of scope |
| **Work Description** | What to implement or modify (components, hooks, pages, API integration) |
| **Design Considerations** | Logic/components involved, trade-offs, interaction with other modules |
| **Alternative Approaches** | Other viable approaches with pros/cons |
| **Cross-cutting Concerns** | Security (XSS/CSRF), performance (Core Web Vitals, bundle), maintainability, accessibility |
| **Figma Analysis Snippet** | 於 **4.2 對應 Figma 分析文件** 時填寫：依本任務範圍對應至 4.2 產出的 Figma 分析文件清單，標註來源檔案並擷取相關片段（如 DOM 樹、Design Token）；多檔時標註對應檔案，單檔時直接引用 |
| **Key Implementation Focus** | Design-level focus only (no code) |
| **Files to Modify/Add** | Full paths (e.g. `src/components/Product/ProductCard.tsx`, `src/hooks/usePromotion.ts`) |
| **Dependencies** | After creation, use Task IDs (e.g. "Task #12456 must complete before #12459") |

Task descriptions should include **Requirements Traceability**: reference the User Story and AC(s) (e.g. User Story #12345 AC2, AC3) for traceability.

---

#### 1.4 Props / API Types / State Specification

**When a task involves component Props, API Request/Response, or shared State types, include a field specification table:**
```markdown
| Field | Type | Required | Description | Notes |
|-------|------|----------|-------------|-------|
| productId | number | ✅ | Product ID | Maps to API |
| name | string | ✅ | Product name | Max 100 chars |
| price | number | ✅ | Price | Currency unit |
| imageUrl | string \| null | ❌ | Image URL | Nullable |
```

**Applies to:** New React component Props, API request/response types, Zustand/Context state shape, shared TypeScript type definitions

---

### 2 Map Figma Analysis Documents (After Task List)

**When:** Run after the initial task list is produced (4.1). At the start of this step, scan `.github/docs/{WORK_ITEM_ID}/` for `figma-analysis-*.md`; if **none are found**, skip this step and proceed to 4.3.

**Steps:**

1. **Enumerate and build Figma analysis document list**  
   Scan `.github/docs/{WORK_ITEM_ID}/` for all `figma-analysis-*.md` files and produce a mapping table for later use:
   ```markdown
   ## Figma Analysis Document List
   | File | Scope / Purpose (from filename or content summary) |
   |------|--------------------------------------------------------|
   | figma-analysis-1.md | e.g. Checkout flow, Checkout screen |
   | figma-analysis-2.md | e.g. Product list, Product list screen |
   ```

2. **Map tasks to files**  
   For each task in the breakdown, use its Context & Scope / screen or flow to match against the list above and determine which `figma-analysis-*.md` file(s) apply.

3. **Fill in Figma Analysis Snippet**  
   For each task:
   - In the task’s **Figma Analysis Snippet** field, note the source file (e.g. `figma-analysis-1.md`);
   - Extract or summarize relevant snippets from that file (e.g. DOM tree, Design Token, layout notes).
   - If a task has no relevant Figma analysis (e.g. API-only, tests, architecture), leave blank or note "N/A".

4. **Confirm with user**  
   Present the Figma document list and the task–to–file mapping (or the task list with Figma Analysis Snippets filled in). Ask: "Figma mapping is done. Confirm the mapping is correct, or specify changes?"

5. **Update task list**  
   After confirmation, treat the task list with Figma Analysis Snippets as the current breakdown for 4.3 (parallel analysis) and 4.4 (presentation).

---

### 3 Analyze Parallelizable Tasks

**[P] criteria (all 4 must be met):**

1. **File independence** — No overlapping file paths with other tasks in the same parallel group
2. **No sequential dependency** — Does not depend on output of other tasks in the same group
3. **No shared state/resources** — Does not modify shared resources (global store, shared context, design tokens, shared types/constants)
4. **Independently testable** — Unit/component tests can run independently

**Process:**
1. Build dependency matrix
2. Prefix parallelizable tasks with **[P]** (e.g. `[F2E][P] 1. Create ProductCard component and types`)
3. Document execution groups:
```
**Group 1 (Parallel):** [P] Task 1, [P] Task 2, [P] Task 4
**Group 2 (After Group 1):** Task 3, Task 5
```
4. Prepare tags: `ParallelGroup-1`, `ParallelGroup-2` (applied in Step 6)

**Execution mode:**

| Mode | Use case | Tag |
|------|-----------|-----|
| **Local (sync)** | High complexity, prototypes, refactors needing oversight | (none) |
| **Cloud (async)** | Feature adds, bug fixes, repetitive work in well-tested repo | `Coding-Agent` |

---

### 4 Traceability Matrix

Before creating Azure DevOps tasks, produce a **Traceability Matrix** so every Acceptance Criterion has at least one corresponding task and every task traces back to requirements.

#### 4.1 Purpose

- **Complete requirements coverage**: Every AC of the User Story has corresponding task(s)
- **Bidirectional traceability**: Requirements → tasks and tasks → requirements
- **Change impact**: Quickly see which tasks are affected when requirements change
- **Progress tracking**: Track requirement implementation via task completion

#### 4.2 Produce Two Mapping Tables

**Matrix 1: User Story AC → Tasks**

| AC ID | Acceptance Criteria | Related Tasks | Coverage Status | Implementation Notes |
|-------|---------------------|---------------|-----------------|----------------------|
| AC1 | (criterion text) | Task #1, #2 | ✅ Fully Covered | Brief division of work |
| AC2 | (criterion text) | Task #2 | ✅ Fully Covered | - |

**Coverage status definitions:**
- ✅ **Fully Covered**: All AC requirements have corresponding tasks
- ⚠️ **Partially Covered**: Only part covered
- ❌ **Not Covered**: No corresponding tasks (add tasks)
- 🔄 **To Be Confirmed**: Confirm with PO whether to implement

**Matrix 2: Tasks → User Story AC (reverse mapping)**

| Task ID | Task Title | Corresponding AC | Estimate | Priority |
|---------|------------|------------------|----------|----------|
| #12346 | [F2E] 1. Create xxx component | AC1 | 3h | P0 |
| #12347 | [F2E] 2. Implement form validation | AC1, AC2 | 4h | P0 |

#### 4.3 Traceability Matrix Checklist (before submit)

**Completeness:**
- [ ] All User Story ACs are in Matrix 1
- [ ] Each AC has at least one corresponding task
- [ ] No AC is Not Covered or To Be Confirmed (unless agreed with PO)
- [ ] Every task traces to at least one AC

**Consistency:**
- [ ] Task acceptance criteria align with User Story ACs
- [ ] Task Context & Scope explicitly reference User Story / AC(s)

**Quality:**
- [ ] Each AC’s coverage status has a short explanation
- [ ] Complex ACs (multiple tasks) have task division notes
- [ ] Cross-task ACs have integration point notes

#### 4.4 Traceability in Task Descriptions

Each task Description should explicitly reference AC(s), e.g.:

```markdown
### Context & Scope
This task implements form validation for the profile edit feature, corresponding to User Story #12345 AC2 (email format) and AC3 (phone format).

### Requirements Traceability
- **User Story**: #12345 - Profile Edit Feature
- **Corresponding ACs**: AC2, AC3
- **Test Verification**: Unit tests in `validation.test.ts`
```
## Hard Constraints

- **No code implementation**: Only plan tasks; must not include actual implementation code
- **Frontend scope only**: Must not include backend implementation planning
- **Time range**: Each Task estimate must fall within 2–8 hours
- **[P] marking criteria**: All 4 [P] conditions must be simultaneously met before marking [P]
- **AC coverage**: Every AC must correspond to at least one Task

## Good/Bad Examples

**✅ Good — Appropriate task granularity via merging**
```
✅ Appropriate (~3 tasks):
- [P] Build product list UI & data layer (ProductCard, ProductList, useProduct, API types + tests)
- [P] Build cart components & state (CartItem, CartSummary, useCart + tests)
- Wire product list & cart APIs and error handling (integration + tests)
```

**❌ Bad — Over-fragmented with missing [P] justification**
```
❌ Over-fine (~10 tasks), all marked [P]:
- [P] Create ProductCard  (shared types not handled → violates condition 3)
- [P] Create API service   (less than 30 min → should be merged)
- [P] Create types
```

## Quality Checklist

- [ ] Each Task is 2–8h, 3–8 files, independently testable
- [ ] Each Task includes all 9 Task Design Document attributes
- [ ] [P] markers meet all 4 [P] conditions
- [ ] Execution Groups have been produced
- [ ] Every AC in the Traceability Matrix is covered (no Not Covered items)
- [ ] Azure DevOps Tasks created only after user confirmation
---