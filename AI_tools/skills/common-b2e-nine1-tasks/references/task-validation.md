# Task Validation — 7-Dimension Validation Logic

---

## Validation Dimensions

| # | Dimension | Check Focus |
|---|------|---------|
| 1 | **Requirement coverage** | Every requirement → mapped to at least one task |
| 2 | **Scope boundary** | Tasks respect Goals / Non-Goals |
| 3 | **Acceptance criteria** | All ACs covered and testable |
| 4 | **Dependency consistency & parallel safety** | Task order matches requirement flow; every `[P]` task pair has no direct dependency, no transitive dependency, and no producer-consumer contract relationship |
| 5 | **Completeness quality** | All task sections have been filled in |
| 6 | **Task size** | 2-4 hours, a functional unit (not a pure code artifact) |
| 7 | **Gap identification** | Whether DB migration, testing, documentation, or monitoring tasks are missing |

---

## Mandatory Parallel Safety Validation

For every `[P]` task pair, confirm each of the following one by one:
- No direct dependency
- No transitive dependency
- No producer-consumer contract relationship (refer to the dependency matrix in `parallel-analysis.md`)
- No shared contract/resource conflict

**If any item fails → the validation result must be `FAIL`; the `[P]` marker must be removed or regrouped, and the task must be sent back to task-breakdown / parallel-analysis for re-planning before proceeding.**

---

## Validation Report Format

```markdown
## 📋 任務拆解驗證報告

**分析日期：** YYYY-MM-DD | **任務總數：** {N} | **狀態：** {PASS / WARNINGS / FAIL}

### ✅ 通過項目
- 需求覆蓋率：100%
- 驗收標準：{N}/{M} 已涵蓋
- 依賴邏輯：順序正確
- 平行安全：所有 `[P]` 任務對均通過合約消費確認

### ⚠️ 警告
1. [AC-2] 效能需求缺少測試任務 → 建議新增「Task X：效能測試」
2. Task 3 缺少錯誤處理規格 → 更新任務說明

### ❌ 嚴重問題
1. Task 6「Redis 快取」違反 Non-Goals → 移除或取得明確核准
2. Task 4 標記 [P] 但消費 Task 3 新建的 `IPromotionService` → 移除 [P] 標記並重新分組

### 📊 覆蓋率摘要
| 維度 | 狀態 | 詳細 |
|------|------|------|
| 需求覆蓋 | ✅ 100% | 全部已涵蓋 |
| 任務大小 | ⚠️ 70% | 3/10 需調整粒度 |
| 平行安全 | ✅ Pass | 所有 [P] 對已驗證 |

### 🔧 必要行動
**必須修正：** 上述問題 1-2
**應新增：** 缺失關注點的任務
**選填：** 釐清記錄更新

### ❓ 需要使用者決定的項目
1. Task 6 快取問題：(A) 移除 (B) 核准 (C) 列為未來改善項目？
2. 任務粒度：(A) 合併 1-3 → 「資料層」 (B) 保持現狀？

**確認：修正問題後重新驗證、處理特定項目，或接受風險繼續？**
```

---

## Decision Logic

```python
if has_critical_issues:
    # Hard stop, must not proceed
    return_to_task_breakdown()
elif has_warnings:
    # Present options, wait for user decision
    prompt_user_for_decision()
else:
    # All validations passed
    proceed_to_step_5()
```
