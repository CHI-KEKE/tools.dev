# 元件選用決策指南

> 此檔案為**範本**，應依各專案實際情況更新。
> 第一次在新專案執行切版時，先完成 Phase 2 的 Codebase 分析，再填入下方表格。

## 決策原則（依序判斷）

```
需要某個 UI 元素？
  ↓
1. Codebase 已有對應的包裝元件？
   → 有：直接用（最優先，保持整個專案一致）
   → 沒有：往下
  ↓
2. 專案使用的 UI Library 有對應元件？
   → 有：用 UI Library
   → 沒有：往下
  ↓
3. 自行實作
```

## 各專案元件清單（切版前填入）

### UI Library

```
專案使用的 UI Library：___（例：@91app/atmos-ui / antd / shadcn/ui / MUI / 無）
import 路徑：___
```

常用元件確認（打勾代表此專案有）：

- [ ] Button
- [ ] Input / TextField
- [ ] Select / Dropdown
- [ ] Checkbox
- [ ] Radio / RadioGroup
- [ ] Table
- [ ] Modal / Dialog
- [ ] Breadcrumbs
- [ ] Pagination
- [ ] Label / Typography
- [ ] Icon（來源：___）

### Codebase 包裝元件

```
包裝元件目錄：___（例：@Component/react-hook-form/）
```

| 元件名稱 | 對應功能 | 特別注意 |
|---|---|---|
| （填入） | （填入） | （填入） |

### 共用 UI 元件

```
共用元件目錄：___（例：@Component/）
```

| 元件名稱 | 用途 | 何時使用 |
|---|---|---|
| （填入） | （填入） | （填入） |

---

## 常見 API 差異提醒

不同元件庫的事件簽名可能不同，使用前先確認：

```bash
# 確認元件的 props 定義
grep -n "onChange\|onSelect\|onCheck" <component-file-path>
```

常見差異：
- `onChange(value)` vs `onChange(event)` vs `onChange(event, value)`
- Checkbox `checked` 是 controlled 還是 uncontrolled
- Select 回傳 `string` 還是整個 option object