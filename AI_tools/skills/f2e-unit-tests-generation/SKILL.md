---
name: f2e-unit-tests-generation
description: Assists front-end development teams in automatically generating unit tests for various front-end components and modules
allowed-tools:
  - read_file
  - file_search
  - create_file
  - run_in_terminal
---

## Preconditions

- Target source file path must be provided
- `package.json` must be accessible (for test framework detection)
- Target project directory must be accessible

**Input:**

* **Target Source File** (required) – Path to the component or module file for which to generate unit tests (e.g., `src/components/Button/Button.tsx`)
* **Optional**: `package.json` and related test configuration files (for auto-detecting test frameworks such as Vitest, Jest)
* **Optional**: `.github/docs/{PARENT_WORK_ITEM_ID}/` – Work item ID for context document storage path

## Workflow Steps

**Output:**

* **Step 1 Output**: Test setup and analysis summary (target component, test framework, code complexity, key findings, suggested mock dependencies)
* **Step 2 Output**: Test plan and category selection confirmation (user-selected test categories: render / functionality / validation, etc.)
* **Step 3 Output**:
  - `{TargetName}.test-data.ts` – Test data
  - `{TargetName}.test-utils.tsx` – Test utilities (required)
  - `{TargetName}.{category}.test.tsx` – Test files generated based on selection (render, functionality, validation)
  - Execution verification summary (file generation status, test case count, dry run results)

**Steps:**

---

### Step 1: Test Setup and Analysis

**Objective**  
Automatically analyze code characteristics and project test environment configuration from the target file provided by the user.

**Completion Criteria**
- Successfully parse source file structure (component/module name, parameters, methods, etc.)
- Auto-detect and confirm the project's test framework (e.g., Vitest, Jest)
- Complete basic test context setup

**Actions**
1. Ask the user to provide the target source file for unit test generation.
2. **Concurrent Analysis**:
   - **Code Analysis**: Parse file structure to identify component name, Props, Hooks, methods, and dependencies.
   - **Environment Analysis**: Scan `package.json` and related config files to auto-detect test framework.
3. Consolidate analysis results and present a concise summary to the user.
4. Update context document with full analysis results.

**Output Format**
```markdown
## 🔍 Test Setup and Analysis Complete

### 📊 Analysis Summary
- **Target Component/Module**: `{componentName}`
- **Test Framework**: `{detectedFramework}` (based on `{detectionSource}`)
- **Code Complexity**: {complexity} (includes {propsCount} Props, {methodsCount} methods)

### 🎯 Key Findings
- **Primary Test Points**: [Suggested key test points, e.g.: async loading, form submission logic]
- **External Dependencies**: [Key dependencies that need mocking, e.g.: apiClient, useAuth]

### 📁 Context Update
- ✓ Test framework and source code analysis results recorded in context document

---
**Next Step**: Step 2: Test Plan and Category Selection
```

---

### Step 2: Test Plan and Category Selection

**Objective**  
Based on analysis results, provide standardized test categories for the user to select and confirm the final test scope.

**Completion Criteria**
- User has completed test category selection; test plan is officially established

**Actions**
1. Provide a standardized test category list with recommended options based on code analysis.
2. **`testUtils`** and **`testData`** are required base files; no selection needed.
3. User selects desired test categories via checkboxes or numeric reply.
4. Confirm user selection and record test plan in context document.

**Output Format**
```markdown
## 🎯 Test Plan and Category Selection

### 📋 Test Category Options
> `testUtils` and `testData` will be created by default.

Please select the test types you need:
1. **render** - Ensure the component renders correctly under different Props and State.
2. **functionality** - Verify that user interactions (clicks, input) trigger correct behavior.
3. **validation** - Test form validation, permission checks, error and boundary conditions.

### ⭐ Recommendation
Based on analysis of `{componentName}`, we recommend selecting at least: **{recommendedCategories}**

**Please reply with your selection (multi-select allowed, e.g.: 1, 2), and I will generate the corresponding test files.**

---
**After confirming your selection, we will proceed to the next step: Test Generation and Execution**
```

---

### Step 3: Test Generation and Execution

**Objective**  
Based on the established test plan, complete all test file generation, code writing, and initial execution verification in one go.

**Completion Criteria**
- All selected test files have been successfully created.
- Test code (including describe, it, expect) within test files has been auto-generated.
- Verify syntax correctness and executability of generated files via `dry run` command.
- Produce final execution result summary.

**Actions**
1. Create corresponding test files based on user-selected categories (e.g., `*.render.test.tsx`, `*.functionality.test.tsx`).
2. Auto-generate test cases in files, including mock data, simulated interactions, and assertions.
3. Run `dry run` for the test command to verify that files can be correctly recognized and executed by the test framework.
4. Consolidate generation results and execution status into a summary report.
5. Update context document.

**Output Format**
```markdown
## ✅ Test Generation and Execution Complete

### 📦 Output Files
- `{TargetName}.test-data.ts` - Test data
- `{TargetName}.test-utils.tsx` - Test utilities
- `{TargetName}.{category}.test.tsx` - (Created based on selection)

### ⚙️ Execution Status
- **File Generation**: ✅ Success ({fileCount} files)
- **Test Cases**: {testCaseCount} total
- **Execution Verification**: ✅ Passed (all files can be recognized by test framework)

### 📁 Context Update
- ✓ File generation and execution results recorded in context document
```

## Hard Constraints

- **Do not modify source code**: Only generate test files; must not modify the target source file
- **testUtils + testData required**: Regardless of which test categories are selected, these two base files must be generated
- **Step order must not be skipped**: Step 1 analysis and Step 2 user confirmation must be completed before proceeding to Step 3 generation
- **Framework detection first**: Must detect the test framework from `package.json`; do not assume
- **Dry run verification**: After Step 3 generation, a dry run must be executed to verify

## Good/Bad Examples

**✅ Good — Step 2 suggests categories tailored to the specific component**
```markdown
## 🎯 Test Plan and Category Selection

### 📋 Test Category Options
> `testUtils` and `testData` will be created by default.

1. **render** - Ensure ProductCard renders correctly when isLoading=false/true
2. **functionality** - Verify that clicking "Add to Cart" triggers the onClick event
3. **validation** - Check that a negative price value displays an error message

⭐ Recommendation: **render, functionality**
```

**❌ Bad — Skipping Step 1/2 and generating test files directly**
```
First reading the file...
(Directly generating all tests without analyzing framework or confirming with user)
```
(May generate tests using the wrong framework API)

## Quality Checklist

- [ ] Step 1 analysis correctly detected the test framework (Vitest / Jest)
- [ ] Step 2 user has confirmed the test category selection
- [ ] `testUtils` and `testData` files have been generated
- [ ] Dry run executed and passed
- [ ] Target source file has not been modified
- [ ] Test file paths match the `{TargetName}.{category}.test.tsx` naming convention
