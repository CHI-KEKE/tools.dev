---
name: f2e-implementing-code
description: Produces front-end implementation scope analysis and full code (components, hooks, pages, API integration) from a Task Design Document. Use when starting feature implementation, implementing designs, or when given an implement command.
allowed-tools:
  - read_file
  - file_search
  - create_file
  - replace_string_in_file
  - run_in_terminal
---

## Preconditions

- Task Design Document must be provided (including Key Implementation Focus, Files to Modify/Add, Design Considerations, Dependencies)
- Target project directory must be accessible
- `implement-plan.md` complete (optional)
- Figma analysis snippets or design artifact documents (optional)

**Input:**

* **Task Design Document** (required), containing:
  - Key Implementation Focus – what to build (components, hooks, pages, API integration)
  - Files to Modify/Add – target file list (e.g. `src/components/`, `src/hooks/`, `src/pages/`)
  - Design Considerations – technical constraints, UI/UX, accessibility
  - Dependencies – other work items or external dependencies
* **Optional**: `.github/docs/{WORK_ITEM_ID}/implement-plan.md` (architecture and file tree alignment)
* **Optional**: Figma Analysis Snippet or design artifact excerpts (if available)

## Workflow Steps

**Output:**

* **Step 1 output**: Formatted Implementation Scope Analysis (focus areas, target files, constraints, dependencies)
* **Step 2 output**:
  - Complete code for each new/modified file (React components, hooks, types, styles)
  - Configuration Notes (if applicable, e.g. env, feature flags)
  - Build/Test Notes (e.g. run `npm run build`, `npm run lint`, `npm run test` to verify)
* **Does not output**: Unit tests or Storybook (handed off to Unit Test / Storybook workflow)


**Step:**
### Step 1 – Analyze Implementation Scope

* Extract from the Task Design Document:
  - **Key Implementation Focus** – what needs to be built (components, hooks, pages, API integration)
  - **Files to Modify/Add** – the target file list (e.g. `src/components/`, `src/hooks/`, `src/pages/`)
  - **Design Considerations** – technical constraints, UI/UX requirements, accessibility
  - **Dependencies** – other work items or external dependencies
* Optionally reference: `.github/docs/{WORK_ITEM_ID}/implement-plan.md` for architecture and file tree alignment

* Display analysis summary:
  ```
  📋 Implementation Scope Analysis

  **Focus Areas**: {implementation focus – e.g. ProductCard component, useCart hook, Cart page}

  **Target Files** (Planned):
  {file list – use tree structure if 5+ files}

  **Key Constraints**: {design considerations}

  **Dependencies**: {if any}
  ```

### Step 2 – Generate & Provide Implementation

* Based on the implementation scope from Step 2.1, generate the code implementation:
  - Provide complete code for each modified/new file (React components, hooks, types, styles)
  - Follow project conventions: **React/TypeScript, Tailwind for styling, early returns, descriptive names, accessibility (aria-*, tabindex, etc.)**
  - Include inline comments for non-obvious logic
  - Reference Design Considerations and Figma Analysis Snippet (if present) in the implementation
  - Provide configuration notes if applicable (e.g. env variables, feature flags)
  - **Build & test**: Prefer using scripts from project `package.json` (e.g. `npm run build`, `npm run lint`, `npm run test`) for verification.

* Format the implementation clearly:
  ```
  🔧 Implementation Artifacts

  **File 1**: {relative/path/to/file1.tsx}
  {code snippet}

  **File 2**: {relative/path/to/file2.ts}
  {code snippet}

  ---

  **Configuration Notes**: {if applicable}
  **Build/Test Notes**: {e.g. run `npm run build` and `npm run test` to verify}
  ```

* ⚠️ **Important**: Do NOT generate or execute unit tests in this step (delegated to Unit Test / Storybook handoff)

## Hard Constraints

- **No Unit Tests**: Tests are handled by `f2e-unit-tests-generation`
- **No Storybook**: Same as above
- **Step order**: Step 1 scope analysis must be completed before proceeding to Step 2 code generation
- **Follow project conventions**: Use commands defined in project `package.json` for verification (npm run build / lint / test)

## Good/Bad Examples

**✅ Good — Step 1 outputs scope analysis first**
```
📋 Implementation Scope Analysis

**Focus Areas**: PromotionCard component, usePromotion hook

**Target Files** (Planned):
src/
├── components/feature/PromotionCard.tsx [NEW]
└── hooks/usePromotion.ts [NEW]

**Key Constraints**: Use atmos-ui Button, no inline styles
**Dependencies**: Task #12345 (API types) must complete first
```

**❌ Bad — Skipping Step 1 and writing code directly**
```tsx
// Directly producing code without scope analysis

export const PromotionCard = () => {
  return <div>...</div>
}
```
(Missing scope confirmation; may implement files incorrectly)

## Quality Checklist

- [ ] Step 1 complete; scope analysis confirmed by author
- [ ] Step 2 provides complete code for each target file
- [ ] Build / lint verified using project `package.json` commands
- [ ] No Unit Tests or Storybook generated
- [ ] TypeScript does not use `any` types