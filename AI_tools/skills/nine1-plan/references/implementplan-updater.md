# ImplementPlan Updater — 更新 Custom.ImplementPlan 規則

---

## 執行前置條件

- Step 4（核心設計）已由使用者確認
- Step 5-6（進階分析）已由使用者確認
- `Custom.ImplementPlan` 欄位存在且可存取

---

## 各 Section 整合規則

| Arc42 Section | 更新來源 | 整合策略 |
|---------------|---------|---------|
| 作法概述 (Approach Overview) | Step 4 核心設計方法 + Step 5 設計決策 | **覆蓋更新**（以新設計為準） |
| Container Diagram | — | **保留既有**（建議手動更新） |
| Component Diagram | — | **保留既有**（建議手動更新） |
| DB Schema | Step 4 (3.4) DB 異動 | **覆蓋更新** |
| API Spec | Step 4 (3.1-3.2) 新增/修改端點職責 | **覆蓋更新** |
| File Tree（新增） | Step 4 (3.3) 完整 File Tree | **新增 Section** |
| Runtime View | Step 6 Mermaid 圖表（若有） | **覆蓋更新**（若無則保留既有） |
| Non Functional Requirements | Step 5 橫切關注點 | **覆蓋更新** |
| Architecture Decisions（選填） | Step 4-5 重要決策（若有） | **新增 Section**（若無則略過） |

---

## 差異比較邏輯

```python
if new_content == existing_content:
    skip_update()
    notify_user("No changes needed")
else:
    update_field()
    show_diff_summary()
```

---

## 執行 Update

```
update_work_item(
    id: workItemId,
    fields: {
        "Custom.ImplementPlan": {integrated_markdown_content}
    }
)
```

---

## 確認訊息格式

```markdown
✅ Custom.ImplementPlan 已更新

**Work Item：** #{workItemId}

**更新摘要：**
- ✅ 作法概述：以新設計方法覆蓋更新
- ⚠️ Container Diagram：保留既有（建議手動更新）
- ⚠️ Component Diagram：保留既有（建議手動更新）
- ✅ DB Schema：更新（{N} 個新增表格，{M} 個修改）
- ✅ API Spec：更新（新增/修改端點與職責）
- ✅ File Tree：新增（{N} 個新增，{M} 個修改）
- ✅ Runtime View：{更新 Mermaid 圖表 / 保留既有（簡單操作）}
- ✅ Non Functional Requirements：更新（Security / Performance / Maintainability）
- {✅/➖} Architecture Decisions：{新增決策表格 / 不適用}

---

⚠️ 需要手動更新的項目：
- 🔶 Container Diagram（系統境界圖）
- 🔶 Component Diagram（內部結構圖）

建議工具：C4-PlantUML、draw.io 或 Mermaid

---

**建議下一步：**
執行 `nine1-tasks` skill 進行任務拆解。
```

---

## 若無需更新

```markdown
ℹ️ Custom.ImplementPlan 無需更新

**原因：** 新設計與既有計畫內容相同，無差異。

**建議行動：**
若預期有更新，請回至 Step 4-6 修改設計後重新執行。
否則，直接執行 `nine1-tasks` skill 進行任務拆解。
```
