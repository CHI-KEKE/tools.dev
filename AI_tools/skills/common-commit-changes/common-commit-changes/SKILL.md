---
name: commit-changes
description: >-
  Generate a correctly formatted git commit message, then execute the commit. Trigger this skill FIRST whenever the user wants to commit — phrases like "commit all changes", "commit these", "幫我 commit", "我要 commit", "提交變更", "commit", or any request to write, generate, or suggest a commit message. Supports VSTS format (VSTS{id} - message) and Conventional Commits (feat/fix/chore: message).
---

# commit-changes

Generate a correctly formatted git commit message and execute the commit.

## Supported Formats

| Type | Format | Example |
|------|--------|---------|
| **VSTS** (default) | `VSTS{id} - {message}` | `VSTS546298 - 折價券後端最小修正` |
| **Conventional** | `{type}: {message}` | `feat: add dispatch limit validation` |

## Workflow

### Step 1 – Check Project Registry (Primary)

Get the repo name: `git rev-parse --show-toplevel` (use the root folder name).

Registry path: `~/.copilot/commit-registry.md`

- If the file does **not exist**, create it using the template below, then proceed to Step 2
- If found, look up the repo name
  - If matched → use the registered format, skip to Step 3
  - If not matched → proceed to Step 2

**Template to create `~/.copilot/commit-registry.md` if missing:**

```markdown
# Commit Format Registry

Maps repository names to their commit message format convention.

Formats:
- `vsts` → `VSTS{id} - {message}`
- `conventional` → `{type}: {message}`

## Registry

| Repo Name | Format | Notes |
|-----------|--------|-------|

---

<!-- When adding a new entry, append a row to the table above. -->
<!-- Repo name = the root folder name of the git repository. -->
```

### Step 2 – Learn from Git Log (Fallback for Unknown Repo)

Run: `git --no-pager log --oneline -10`

- If commits match `VSTS\d+` pattern → **VSTS** format detected
- If commits match `feat:|fix:|chore:` pattern → **Conventional** format detected
- If mixed or no history → ask the user which format to use

After determining the format, **update the registry** by appending a new row to `~/.copilot/commit-registry.md`:

```markdown
| my-repo | vsts | 後端專案 |
```

Use `| {repo-name} | {vsts or conventional} | {one-line note} |` format so future calls skip this step.

### Step 3 – Inspect Changes

Run: `git --no-pager diff --stat HEAD` (or `git status --short` if nothing staged yet)

Use the changed files and summary to inform the subject line and body.

### Step 4 – Generate the Commit Message

**For VSTS format:**
- Extract the VSTS/Azure DevOps Work Item ID from context (user input, branch name, or ask)
- Branch name pattern: `feature/VSTS{id}-*` or `fix/VSTS{id}-*`
- Format: `VSTS{id} - {concise description in the repo's primary language}`

**For Conventional format:**
- Choose the appropriate type: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `style`
- Format: `{type}({optional scope}): {concise description}`

### Step 5 – Multi-line Body (Optional)

If the change involves multiple files or logical groups, append a body:

```
VSTS546298 - 折價券後端最小修正

- ECouponService: 放寬 MaxQtyPerDispatch 回寫條件
- ECouponDataValidService: 更新 XML 文件說明
- ECouponDispatchSettingTests: 新增 10 個單元測試
```

Only add a body when there are 3+ distinct changes worth highlighting.

### Step 6 – Confirm and Execute

Present the final commit message to the user, then use the `ask_user` tool with the following choices to wait for confirmation:

- **"確認，執行 commit"** → proceed with commit
- **"修改訊息"** → ask for changes, regenerate message, repeat Step 6
- **"取消"** → abort, do not commit

```bash
git add -A && git commit -m "{message}"
```

If the user specifies particular files to stage, stage only those instead of `-A`.

## Rules

- Keep the subject line under 72 characters
- Use the repo's primary language for the description (check git log for language hints)
- For VSTS format: **do NOT include conventional commit type prefixes** (no `feat:`, `fix:` etc.)
- For backend repos using VSTS format: description is plain prose, not typed
- Always confirm the final message before executing the commit
