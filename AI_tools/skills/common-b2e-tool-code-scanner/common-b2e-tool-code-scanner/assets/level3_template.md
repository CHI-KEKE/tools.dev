# 📄 {類別名稱} 盤點

> **一句話摘要**：{這個類別的核心職責及在整體流程中的角色，25 字以內}

## 基本資訊
- **檔案路徑**：`{src/ModuleName/Services/ClassName.cs}`
- **命名空間**：`{Company.Module.Services}`
- **類型**：{Class | Interface | Enum | Abstract Class | Static Class | Record}
- **繼承/實作**：{`BaseClass`, `IInterface`（若無填「無」）}
- **行數**：{N} 行

### 建構子依賴（注入的服務）
| 依賴介面/類別 | 推測用途 |
|---|---|
| `{IServiceName}` | {用途推測} |
| `{IRepositoryName}` | {用途推測} |

*若無建構子依賴（static class 或 無狀態類別），填：「無建構子依賴。」*

## 公開方法清單
| 方法名稱 | 用途 | 參數摘要 | 回傳值 | 行數 | 備註 |
|---|---|---|---|---|---|
| `{MethodName}()` | {用途} | `{Type} {name}` | `{ReturnType}` | {N} | {async/主要進入點} |
| `{MethodName}()` | {用途} | `{Type} {name}, {Type} {name}` | `{ReturnType}` | {N} | {async} |

*若為 Interface，改標題為「介面方法清單」，行數欄位填「—」*
*若為 Enum，刪除此段，改用「列舉值清單」表格*

## 核心邏輯摘要

### {長方法名稱}() 流程
1. {步驟 1：動作（呼叫 `{_dependency.Method()}`）}
2. {步驟 2：動作（本地邏輯）}
3. {步驟 3：動作（呼叫 `{_dependency.Method()}`）}

*若無方法行數超過 50 行，填：「所有方法行數較短，無需特別說明流程。」*

## 注意事項 / 技術債
- ⚠️ `{MethodName}()` 方法過長（{N} 行），建議依職責拆分
- ⚠️ 第 {N} 行有硬編碼 magic number：`{value}`（建議提取為常數）
- ⚠️ 第 {N} 行有硬編碼字串：`"{value}"`
- ℹ️ 有 TODO 註解 {N} 處（第 {N1}、{N2} 行）

*若無技術債，填：「✅ 無明顯技術債。」*

---
*盤點時間：{YYYY-MM-DD HH:MM}*
