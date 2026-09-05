# Question Generation — Ambiguity Question Generation Rules & Multi-Round Strategy

---

## Ambiguity Question Generation Rules

1. Only generate questions whose answer **would materially affect** architecture, data model, task breakdown, or test strategy
2. Skip questions already **answered** in the Work Item or existing comments
3. Sort by **Impact × Uncertainty** score (see `ambiguity-taxonomy.md`)
4. **Max 5 questions per round**, **prioritize exhausting the highest-impact category's ambiguities before moving to the next category** (depth-first, not one question per category)
5. Each question must be answerable via: multiple choice (2-5 options) **or** short answer (≤5 words)
6. Each question **must** include a recommended answer with a 1-2 sentence rationale (Traditional Chinese)

---

## Presentation Format

```markdown
## 🔍 關鍵需求釐清

我已識別出 {count} 個關鍵模糊點需要釐清：

---

### 問題 1: [類別英文 / 類別中文] - {問題標題}

**💡 推薦答案：{選項字母 or 簡答建議}**
**理由：** {1-2 句理由，繁體中文}

| 選項 | 說明 |
|-----|------|
| A | ... |
| B | ...（推薦） |
| 自訂 | 提供簡短答案（≤5 字） |

---

### 問題 N: [類別英文 / 類別中文] - {問題標題}

**💡 建議答案：{簡答建議}**
**理由：** {1-2 句理由，繁體中文}

**格式：** 簡短答案（≤5 字）

---

## 📝 回覆方式

**快速接受所有推薦：**
- 回答 "全部接受" 或 "yes to all" 或 "接受所有推薦"

**個別回答：**
- 格式範例：`1: A, 2: yes, 3: 使用 UnitOfWork, 4: B, 5: yes`

**需要重新說明某題？**
- 指定問題編號，例如："第 3 題不太懂"

**請提供您的回答：**
```

---

## Answer Parsing Logic

| Input Form | Handling |
|---------|---------|
| `全部接受` / `yes to all` | Adopt all recommended answers, proceed to validation confirmation |
| `1: A, 2: yes, 3: 自訂文字` | Parse question-by-question; `yes`/`suggested` adopts the recommended answer |
| Ambiguous answer | Ask for clarification on that question (max 2 times), then fall back to the closest option after 2 attempts |
| Request to explain a question | After providing additional explanation, re-present only that question |

**Recording rule (when writing to VSTS):**
- ✅ Record: `使用 httpOnly cookie`
- ❌ Do not record: `選項 B`、`yes`、`接受建議`、`suggested`

---

## Multi-Round Strategy

**Trigger point: after SKILL.md Step 6 (write to VSTS Discussion) succeeds**, evaluate whether any high-impact ambiguities remain:

```python
remaining = [c for c in categories if c.status in ["Partial", "Missing"] and c.impact >= 7]

if remaining:
    prompt_continue()                  # -> [Y]/[N]/[S] options, see prompt below
else:
    proceed_to_arc42_validation()      # -> proceed directly to SKILL.md Step 7
```

If high-impact ambiguities remain, prompt the user to choose the next step:

**Prompt the user (Traditional Chinese):**
```markdown
## 📄 本輪模糊點釐清完成

**本輪已釐清：** {N} 個問題
**剩餘潛在模糊點：** {M} 個

| 類別 | 狀態 | 影響程度 |
|-----|------|---------|
| ... | ⚠️ Partial | High |
| ... | ✅ Clear | - |

**是否需要繼續釐清模糊點？**
- **[Y]** 是，再提出最多 5 個問題
- **[N]** 結束釐清，執行 plan 前品質把關：讀取工單 Description、**ImplementPlan（Arc42 各段落）**與 Clarifications 留言，評估現有內容是否足以讓 common-b2e-nine1-plan 生成架構設計（**唯讀，不寫入工單**）
          → 建議：仍有 Partial 模糊點、或不確定 ImplementPlan 内容是否足以支撐 common-b2e-nine1-plan 順利啟動時選擇此項
- **[S]** 跳過品質把關，直接輸出 clarify 階段摘要（剩餘模糊點標記 Deferred）
          → 建議：需求已明確、時程緊迫，可接受 common-b2e-nine1-plan 在資訊不完整的情況下啟動的風險時選擇此項
```

**Execution logic:**
- `[Y]` → back to SKILL.md Step 4 (Round +1); **after the next round ends, must return to Step 6 to write to VSTS again**
- `[N]` → run Arc42 readiness validation (SKILL.md Step 7)
- `[S]` → skip to the final summary (SKILL.md Step 8), mark remaining categories as Deferred

---

## Recommended Answer Generation Strategy

When generating recommended answers, consider:
1. **Best practices**: industry-standard approaches (OAuth 2.0, REST API conventions, SOLID principles)
2. **Risk reduction**: security vulnerabilities, performance bottlenecks, maintenance burden
3. **91APP context**: the team's existing experience with .NET Framework and existing architecture patterns
4. **Pragmatism**: balance ideal solution vs. implementation complexity vs. schedule constraints

Rationale template:
```
"降低 {具體風險}，符合 {標準或最佳實踐}，並{91APP 背景情境}"
```
