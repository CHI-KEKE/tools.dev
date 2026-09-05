# 🚀 AI Code Review — 搬移到新 GitLab Repo 操作指南

> 目前 repo（GitHub `kevindeng91app/NineYi.Ai.Code.Review.V2`）已非正式 repo，需將程式碼搬至新的 GitLab repo。

## 📋 目前狀態

| 項目 | 說明 |
|------|------|
| 舊 repo | `https://github.com/kevindeng91app/NineYi.Ai.Code.Review.V2` |
| 舊 repo 路徑 | `C:\91APP\AI_Devs\codereview\NineYi.Ai.Code.Review.V2` |
| 新 repo | GitLab（URL 待補） |
| 新 repo 路徑 | `C:\91APP\AI_Devs\codereview\NineYi.Ai.Code.Review`（建議） |
| 搬移策略 | **只搬程式碼**（不帶 git history） |
| 目前工作分支 | `feature/Webhook實作` |

---

## 🪜 操作步驟

### ⬜ Step 1：確認舊 repo 程式碼乾淨

```powershell
cd "C:\91APP\AI_Devs\codereview\NineYi.Ai.Code.Review.V2"
git status
```

> 確認沒有未 commit 的修改。如果有，先 commit 或 stash。

---

### ⬜ Step 2：Clone 新的空 GitLab repo

```powershell
git clone <新GitLab URL> C:\91APP\AI_Devs\codereview\NineYi.Ai.Code.Review
```

> 🔗 新 GitLab URL：**（拿到後填在這裡）**

---

### ⬜ Step 3：用 robocopy 複製程式碼

```powershell
robocopy `
  "C:\91APP\AI_Devs\codereview\NineYi.Ai.Code.Review.V2" `
  "C:\91APP\AI_Devs\codereview\NineYi.Ai.Code.Review" `
  /E `
  /XD .git .vs bin obj logs data `
  /XF "*.user"
```

**排除的項目說明：**

| 排除項目 | 原因 |
|----------|------|
| `.git` | 新 repo 有自己的 git，絕對不能覆蓋 |
| `.vs` | Visual Studio 個人設定，不需要 |
| `bin` / `obj` | Build 產出物，不需要 |
| `logs` | Runtime log，不需要 |
| `data` | Runtime 資料（SQLite / JSON config），不需要 |
| `*.user` | VS 個人偏好設定，不需要 |

> ⚠️ robocopy 結束後 exit code 1 或 3 是**正常的**，代表有檔案成功複製，不用擔心。

---

### ⬜ Step 4：開 feature branch

```powershell
cd "C:\91APP\AI_Devs\codereview\NineYi.Ai.Code.Review"
git checkout -b feature/webhook-implementation
```

---

### ⬜ Step 5：確認複製結果正確

```powershell
git status
```

> 應該看到一堆 `new file`。
> 確認**沒有** `bin/`、`obj/`、`.vs/` 出現在清單裡。

---

### ⬜ Step 6：Commit 並 Push

```powershell
git add .
git commit -m "feat: AI Code Review 初版實作"
git push origin feature/webhook-implementation
```

---

### ⬜ Step 7：在 GitLab UI 開 MR

- **Source branch**：`feature/webhook-implementation`
- **Target branch**：`main`

---

## 📝 備註

- `robocopy` 是 Windows 內建工具，不需要安裝
- 搬移完成後，舊 GitHub repo 可以封存（Archive）不用刪除
- 新 repo 的 `.gitlab-ci.yml` 已存在於舊 repo 中，會一起被複製過去
