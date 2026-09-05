# Phase 1 — Enum 定義

> 讀完本文件後再開始修改對應檔案。

---

## 通用規則

- 三個 enum 使用**各自獨立的 bit space**，不可共用相同數值
- 皆使用 `1L << N` bit-shift 格式
- 新值必須加在**最後一個既有 enum value 之後**
- `PayProfileTypeEnum` 的新值必須加在 `CommonThirdPartyPayType` 複合 flag **之前**
- 所有 enum 值必須附上 XML 文件說明

---

## 檔案 1：PayProfileTypeEnum.cs

**路徑：** `BusinessLogic/BE/PayProfile/PayProfileTypeEnum.cs`

**動作：**
1. 找到最後一個 enum value，取得下一個 bit 位（1L << N+1）
2. 在其後加入新值（需在 `CommonThirdPartyPayType` 複合 flag 定義之前）
3. 加入 XML 文件說明

**範例：**
```csharp
/// <summary>
/// Razer PayNow 付款
/// </summary>
PayNow_Razer = 1L << 54,
```

**驗證：**
- [ ] bit-shift 值不與其他值重複
- [ ] XML 文件完整
- [ ] 位置在 `CommonThirdPartyPayType` 之前

---

## 檔案 2：PayProfileStatisticsTypeEnum.cs

**路徑：** `BusinessLogic/BE/PayProfile/PayProfileStatisticsTypeEnum.cs`

**動作：**
1. 找到最後一個 enum value，取得下一個 bit 位
2. 加入新值
3. **通常不加入** `CommonThirdPartyPayType` 複合 flag

**範例：**
```csharp
/// <summary>
/// Razer PayNow 統計類型
/// </summary>
PayNow_Razer = 1L << 50,
```

**驗證：**
- [ ] bit-shift 值在此 enum 中唯一（與 PayProfileTypeEnum 的值可相同，屬不同 enum）
- [ ] XML 文件完整
- [ ] 確認是否需要加入 `CommonThirdPartyPayType`（一般 PaymentMiddleware 不加）

---

## 檔案 3：RefundRequestTypeDefEnum.cs

**路徑：** `BusinessLogic/BE/RefundRequests/RefundRequestTypeDefEnum.cs`

**動作：**
1. 找到最後一個 enum value，取得下一個 bit 位
2. 加入新值

**範例：**
```csharp
/// <summary>
/// Razer PayNow 退款類型
/// </summary>
PayNow_Razer = 1L << 38,
```

**驗證：**
- [ ] bit-shift 值在此 enum 中唯一
- [ ] XML 文件完整

---

## Bit-Shift 計算方式

讀取三個檔案後，列出已使用的 bit 值，找出各自的 max N，新值使用 N+1：

| Enum 檔案 | 目前最大 N（範例） | 新值使用 |
|-----------|-------------------|----------|
| PayProfileTypeEnum | 53 | 1L << 54 |
| PayProfileStatisticsTypeEnum | 49 | 1L << 50 |
| RefundRequestTypeDefEnum | 37 | 1L << 38 |

> ⚠️ 實際數值需讀取各檔案後動態計算，上表僅為示意。
