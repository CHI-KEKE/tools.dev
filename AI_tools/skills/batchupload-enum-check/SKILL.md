---
name: batchupload-enum-check
description: >
  檢核 NineYi.Sms 專案中 BatchUpload 相關 enum 的一致性，確保 TypeScript 檔案與 C# 來源保持同步。
  主要用途：解決 merge conflict 後驗證 enum 值是否正確、偵測衝突殘留（duplicate values）、修正 TS 與 C# 不一致的項目。

  當使用者說「檢查 batchupload enum」、「enum 一致性」、「enum 檢核」、「解衝突後確認 enum」、
  「BatchUpload enum 有沒有問題」、「TS 和 CS enum 對不對」、「BatchUploadTypeDefEnum」、
  「BatchUploadExecuteTaskTypeEnum」、「Enums.ts 和 CS 比對」、「enum.ts 對不對」、
  「merge 後確認 enum」、「enum 有沒有差異」，都應立即使用此 skill。
---

# BatchUpload Enum 一致性檢核

此 skill 協助驗證並修正 NineYi.Sms 專案中 BatchUpload enum 相關的四個檔案之間的一致性。
特別適合在 merge conflict 解衝突後執行，確保沒有殘留錯誤。

---

## 目標檔案

| 角色 | 路徑 |
|------|------|
| C# 來源（Type Def） | `BusinessLogic/BE/BatchUploads/Enums/BatchUploadTypeDefEnum.cs` |
| C# 來源（Execute Task） | `BusinessLogic/BE/BatchUploads/Enums/BatchUploadExecuteTaskTypeEnum.cs` |
| TS 完整鏡像 | `WebSite/WebSite/Scripts/Enums.ts` |
| TS ClientApp（部分） | `WebSite/WebSite/ClientApp/package_cloud/common/src/typings/enum.ts` |

---

## 一致性規則（兩層級）

理解這兩個 TS 檔案的不同職責是整個流程的核心：

**Tier 1 — `Enums.ts`（完全一致）**
- 必須與 C# 完全相同：成員名稱、值、數量皆須一致
- 缺少任何 C# 成員 → 需補充
- 名稱不同 → 需修正
- 值不同 → 需修正

**Tier 2 — `enum.ts`（名稱與值需一致，但不要求完整列表）**
- 現有成員的**名稱**與**值**均須與 C# 相同
- 缺少 C# 的成員 → 可接受（不用補充）
- 現有成員名稱與 C# 不同 → 需修正
- 現有成員的值與 C# 不同 → 需修正

---

## 讀取 C# Enum 的關鍵注意事項

**兩個 C# enum 檔案都很大（22–24KB），必須分段讀取完整內容。**

C# enum 中的成員若沒有明確指定值，會從 0 開始自動遞增。這兩個 enum 都完全使用自動遞增（沒有任何 `= N` 賦值），所以：
- 第 1 個成員 = 0，第 2 個成員 = 1，依此類推
- 任何明確的 `= N` 賦值（若存在）都會打斷自動遞增，後續繼續從該值開始

讀取 C# 檔案時，使用 `view_range` 分多段讀取（建議每段 100 行），並在腦中維護計數器。

---

## 執行流程

### 第 1 步：讀取全部 C# enum 成員並建立對照表

分別讀取兩個 C# 檔案，建立「成員名稱 → 數值」的完整對照表。

以 `BatchUploadTypeDefEnum.cs` 為例（約 500+ 行）：
```
view_range: [1, 100]   // 前 100 行
view_range: [101, 200] // 下 100 行
... 依此類推，直到讀完 enum 的最後一個成員
```

**注意跳過的行：**
- `/// <summary>` 等文件注釋行
- `public enum BatchUploadTypeDefEnum` 宣告行
- `{` 和 `}` 括號行
- 空行

只計算包含實際成員名稱的行。

### 第 2 步：偵測衝突殘留（Conflict Residuals）

Merge conflict 解衝突後常見的問題：同一個 integer 值對應到兩個不同名稱的成員（因為 `<<<`, `>>>`, `===` 標記被刪除但內容保留了兩份）。

在讀取 TS 檔案時，特別注意：
- **重複值警告**：若兩個成員有相同的數值，幾乎必定是衝突殘留
- **成員數量異常**：若 TS 比 C# 多出成員，也是疑似殘留

### 第 3 步：讀取並比對 `Enums.ts`

`Enums.ts` 非常大（約 82KB），需用 `view_range` 讀取 BatchUpload 相關段落。

在 `Enums.ts` 中找到 `BatchUploadTypeDefEnum` 和 `BatchUploadExecuteTaskTypeEnum` 的定義區段，逐項對比 C# 對照表：

```
對每個 enum.ts 現有成員：
  ✓ 名稱是否與 C# 對應成員一致？
  ✓ 值是否正確？
```

**TS enum 的值計算：**
- 若 TS 成員有明確的 `= N`，使用 N
- 若沒有，從 0 開始自動遞增（與上一個有值的成員後繼續）

### 第 4 步：讀取並比對 `enum.ts`

以相同方式讀取 `enum.ts`，但套用 Tier 2 規則（只檢查現有成員的值）。

### 第 5 步：整理差異報告

輸出一份清楚的差異報告，包含：

```
## BatchUploadTypeDefEnum 差異

### Enums.ts（需完全一致）
| 問題類型 | 成員名稱 | C# 值 | TS 值 | 說明 |
|---------|---------|-------|-------|------|
| 值錯誤   | BatchReservationOrderExport | 196 | 195 | 需修正 |
| 缺少成員 | SomeNewMember | 197 | 不存在 | 需補充 |

### enum.ts（僅值需一致）
| 問題類型 | 成員名稱 | C# 值 | TS 值 | 說明 |
|---------|---------|-------|-------|------|
| 值錯誤   | BatchOrderConfirm | 159 | 159（名稱為 ModifyCustomTagsInBatches，可接受） | 值正確，略 |
| 衝突殘留 | MemberCollectionDetailMemberCode | 144 | 144（重複值） | 需移除 |
```

### 第 6 步：執行修正

根據差異報告，按以下優先順序修正：

1. **移除衝突殘留**（重複值的成員）— 優先處理，避免後續值計算錯亂
2. **修正錯誤的值**
3. **修正錯誤的成員名稱**（僅 Enums.ts）
4. **補充缺少的成員**（僅 Enums.ts）

修正後驗證：重新過一遍確認所有項目都已正確。

---

## 常見問題與處理方式

### 問題一：TS 有兩個成員值相同

```typescript
// 這是衝突殘留！
MemberCollectionDetailMemberCode = 144,
MemberCollectionDetailCellphone = 145,  // 應移除
```

處理：移除多餘的成員（通常是 value 較小那個，或與 C# 名稱不符的那個）。

### 問題二：成員名稱對不上但值正確

```typescript
// enum.ts 中
BatchExportProductBadgeSalePage = 130,  // C# 名稱是 ExportProductBadgeSalePage
```

處理：不論是 enum.ts 或 Enums.ts，名稱與 C# 不符都需要修正。

### 問題三：Enums.ts 缺少 C# 新增的成員

處理：在 Enums.ts 的對應位置補充成員，確保值正確（可使用顯式 `= N` 確保對齊）。

### 問題四：C# 最後幾個成員在 TS 的值偏移

這通常是因為 TS 中途有衝突殘留導致計數錯誤。先移除殘留後再重新計算。

---

## 修正後的驗收標準

- `Enums.ts` 中 `BatchUploadTypeDefEnum` 和 `BatchUploadExecuteTaskTypeEnum` 的每個成員，名稱和值均與 C# 完全一致
- `enum.ts` 中所有現有成員的**名稱**和**值**均與 C# 對應成員相同
- 兩個 TS 檔案中均無重複值（除非 C# 本身有重複，實際上不會）
- 成員數量：`Enums.ts` 成員數 = C# 成員數；`enum.ts` 成員數 ≤ C# 成員數
