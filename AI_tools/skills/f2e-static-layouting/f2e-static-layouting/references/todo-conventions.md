# TODO / FIXME 註解慣例

靜態切版的目的是讓後續開發者可以依照這些標記，一步步完成真實實作。
每個標記都應該清楚說明「要做什麼」，而不只是「這裡有東西要做」。

---

## 標記類型

| 標記 | 用途 | 範例情境 |
|---|---|---|
| `// TODO:` | 需要補實作的功能，靜態切版暫時跳過 | API 串接、表單驗證、i18n |
| `// FIXME:` | 已知有問題、待修正的實作 | Icon 找不到暫用 placeholder、Token 對應不確定 |

---

## 標準 TODO 類型與格式

### API 串接

```tsx
// TODO: API - 替換為實際 API，回傳型別參考 type.ts IXxxItem
const data = MOCK_LIST;
```

```tsx
// TODO: API - 呼叫 POST /api/xxx，成功後導回列表頁
const onSubmit = (values: IFormValues) => {
  console.log('submit', values);
};
```

### 表單驗證

```tsx
// TODO: Validation - 補上 yup / zod schema，規則參考設計稿的錯誤提示文字
const { control, handleSubmit } = useForm<IFormValues>({
  defaultValues: MOCK_FORM_DEFAULT,
});
```

### i18n

```tsx
// TODO: i18n - 替換為 t('key')
<Label text="群組名稱" />
```

### 權限控管

```tsx
// TODO: Auth - 依實際權限設定 disabled 狀態，參考 useCheckAuth
<Button disabled={false}>儲存</Button>
```

### 互動邏輯

```tsx
// TODO: Logic - 實作篩選條件與 API 查詢參數的對應
const onFilter = (values: IFilterValues) => {
  console.log('filter', values);
};
```

```tsx
// TODO: Logic - 實作分頁，帶入 page / pageSize 參數
const onPageChange = (page: number) => {
  console.log('page', page);
};
```

### 狀態管理

```tsx
// TODO: State - 整合 React Query / Zustand / Context，移除本地 useState
const [list, setList] = useState(MOCK_LIST);
```

### Icon 找不到

```tsx
{/* FIXME: Icon - 找不到 CommonXxxIcon，暫用 placeholder，請確認 icon 名稱後替換 */}
<img src="https://placehold.co/24x24" width={24} height={24} alt="" />
```

### Token 不確定

```tsx
{/* FIXME: Token - #1b9a00 尚未確認對應的專案 Token，請對照 tailwind.config 後替換 */}
<span className="text-[#1b9a00]">是</span>
```

### 元件找不到

```tsx
{/* FIXME: Component - Codebase 找不到 <ChipComponent>，暫用 <span> 替代，確認後替換 */}
<span className="text-xs bg-gray-100 px-2 py-0.5 rounded">已結束</span>
```

---

## 書寫原則

- **說清楚要做什麼**，不要只寫 `// TODO`
- **標明參考位置**（API endpoint、type 名稱、設計稿欄位名）方便接手者查找
- **一個 TODO 對應一個具體任務**，不要把多件事堆在一個註解
- **FIXME 說明暫時方案是什麼**，讓接手者知道現在用的是什麼、該換成什麼

---

## 靜態切版完成後的 TODO 清單

切版完成時，在 `index.tsx` 頂部加上整頁的 TODO 總表，方便後續開發一次掃清：

```tsx
/**
 * TODO List（靜態切版 → 正式實作）
 *
 * [ ] API    - GET  /api/xxx/list（列表資料）
 * [ ] API    - POST /api/xxx（新增）
 * [ ] Valid  - 補上表單驗證 schema
 * [ ] Auth   - 依權限控制按鈕 disabled
 * [ ] i18n   - 所有中文字串替換為 t('key')
 * [ ] State  - 整合 React Query，移除 MOCK_LIST
 * [ ] FIXME  - CommonXxxIcon 找不到（共 2 處）
 */
```