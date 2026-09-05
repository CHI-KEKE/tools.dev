---
name: csharp-codegen-rules
description: 個人 C# code generation 規範清單，定義撰寫/新增/修改 C# 程式碼時必須遵守的強制規則（如方法必須有完整 XML 註解、if 陳述式必須加大括號等）。任何時候要在 C# 專案（含 NineYi.Sms、nine1.regularpurchase.v2 等）新增或修改方法、類別、if/else 判斷式時，都必須套用此 skill 的規則，無論該專案自身的 .github/instructions 是否已有規定——此 skill 的規則優先於「找不到規範」的預設寫法，但不得與專案本身明確寫出的規則衝突。
---

# C# Code Generation Rules

## Overview

此 skill 記錄個人對 C# 程式碼撰寫的強制規範，補足各專案 `.github/instructions` 未涵蓋的細節。每次進行 C# code generation（新增方法、新增類別、修改邏輯）時都必須套用以下規則。

## 強制規則

### Rule 1：所有新增的方法都必須有完整 XML 註解

新增或新建的方法，**不論存取修飾詞（public/protected/internal/private 皆適用）**，只要方法內含實質邏輯（分支判斷、try/catch、迴圈、跨層呼叫等，非單純一行轉發/getter），都必須加上完整的 `///` XML 文件註解，格式如下：

```csharp
/// <summary>
/// 取得宅配查詢清單
/// </summary>
/// <param name="searchEntity">查詢條件</param>
/// <param name="skip">起始索引</param>
/// <param name="take">取得筆數</param>
/// <param name="customMemoDisplayMode">備註顯示模式</param>
/// <returns>
/// 宅配查詢清單
/// </returns>
```

要點：
- **`private` 方法不是例外**：只要方法有實質邏輯（例如帶 try/catch 的反序列化、有分支判斷的資料轉換），就必須用完整 `///` XML 註解，不能只用 `////` inline 註解帶過——`////` 只適合單行、無分支的極簡輔助方法或程式碼片段說明，不能取代方法層級的 XML 文件註解。
- `<summary>` 用一句話描述方法做什麼（中文）。
- 每個參數都要有對應的 `<param name="...">`，逐一說明用途。
- `<returns>` 獨立成多行區塊（如上例），說明回傳內容。
- **interface 與其實作類別（implementation）都必須各自寫出完整可見的 XML 註解**，不可用 `/// <inheritdoc/>` 取代——`<inheritdoc/>` 只有在產生文件工具展開時才看得到內容，直接閱讀原始碼看不到任何說明，不符合「完整註解」要求。即使 interface 與 impl 註解文字重複，也要各自完整撰寫。
- 若該方法涉及既有邏輯遷移或關鍵業務規則，且專案本身有 WHY/EDGE/RISK/VERIFY 註解慣例（見該專案的 `code_generation.instructions.md`），一併補上，不與此規則衝突。

### Rule 2：`if (...)` 一律要有大括號

任何新增或修改的 `if`、`else if`、`else`、`for`、`foreach`、`while` 等區塊，即使內容只有一行，都必須加上 `{}`，不可省略。

錯誤範例（禁止）：
```csharp
if (product == null)
    return RegularProductResult<ProductQueryResponse>.Failure("查無資料");
```

正確範例（必須）：
```csharp
if (product == null)
{
    return RegularProductResult<ProductQueryResponse>.Failure("查無資料");
}
```

適用範圍：
- 僅強制套用在**本次新增或修改**的程式碼上。
- 若專案既有程式碼（未被本次改動觸及的部分）使用單行 `if` 不加大括號，維持原樣，不需要順手修改，除非使用者明確要求一併修正。

### Rule 3：要有足夠的 null reference 防呆

新增或修改的方法，凡是使用外部輸入、跨層呼叫結果（DB 查詢、HTTP/API 回應、Repository/Service 回傳值）或可為 null 的屬性時，必須加上足夠的 null 檢查，避免 NullReferenceException。

要點：
- 方法參數若為 reference type 且理論上可能為 null（尤其是跨層呼叫傳入的 request/entity），視情況加上 guard clause（`if (xxx == null) { return ...; }` 或 `ArgumentNullException`），依 Rule 2 加大括號。
- 呼叫回傳可能為 null 的方法（例如 `LoadByPlanAsync`、`GetSalePageAsync` 這類查無資料回傳 null 的方法）後，使用結果前必須先檢查 null，不可直接存取其屬性。
- 存取巢狀物件屬性（如 `a.b.c`）時，優先使用 `?.`（null-conditional）與 `??`（null-coalescing）處理中間節點可能為 null 的情況，而非假設全部一定有值。
- 集合（List/Array/Dictionary）在使用前應確認非 null，可用 `?? []`或初始化為空集合，避免 foreach/Count 對 null 集合丟例外。
- 不要為了消除警告而使用 null-forgiving operator（`!`）掩蓋真正可能為 null 的情況；若確定不可能為 null 需在註解中說明原因（呼應 Rule 1 的 VERIFY 標記）。

### Rule 4：新增/修改的 class 欄位（property/field）也必須要有註解

新增或修改的 class 內 property/field，都必須加上 `///` XML 註解說明其用途與來源，格式如下：

```csharp
/// <summary>
/// 已售數量（工作項目 #647549 補齊：來源為 SCM 商品頁即時資訊 RegQty - CancelQty；
/// 商品頁已不存在時為 0）
/// </summary>
public int SoldQty { get; set; }
```

要點：
- **`<summary>`、`</summary>` 一律各自獨立成一行，絕對禁止寫成單行 `/// <summary>xxx</summary>`**，即使內容只有短短一句話也一樣。正確格式固定為：

```csharp
/// <summary>
/// 商品標題
/// </summary>
public string Title { get; set; } = string.Empty;
```

錯誤範例（禁止，即使內容很簡短也不行）：
```csharp
/// <summary>商品標題</summary>
public string Title { get; set; } = string.Empty;
```

- `<summary>` 至少說明「這個欄位是什麼」；若欄位有非顯而易見的來源、計算方式、預設值或邊界情況（如「查無資料時為 0/null」「對應 DB 哪個欄位」），也要一併寫入同一個 `<summary>` 內（可換行接續多行），不需要額外拆 `<remarks>`。
- 即使是簡單欄位（如 `Title`、`PicUrl`），也必須要有 `<summary>` 說明用途，不可完全不寫註解，也不可為了省行數而壓成單行格式。
- 巢狀/集合型別欄位（如 `List<XxxEntity>`）也要說明清單內容代表什麼、可能為空清單的情境。

### Rule 5：方法簽章（參數列）能放在同一行就不要刻意換行

新增/修改的方法宣告，若整個簽章（含修飾詞、回傳型別、方法名稱、所有參數）長度沒有超出一般行寬（約 120 字元），就必須寫在同一行，不可為了「看起來整齊」或習慣性換行而把參數拆到下一行。只有在簽章真的過長（參數很多或型別名稱很長）時才允許換行。

正確範例（短簽章，放同一行）：
```csharp
Task<RegularProductResult<PlanQueryResponse>> QueryProductByPlanAsync(long shopId, long planId);
```

錯誤範例（禁止，短短的參數卻硬拆行）：
```csharp
Task<RegularProductResult<PlanQueryResponse>> QueryProductByPlanAsync(
    long shopId, long planId);
```

要點：
- 判斷標準以「是否真的放不下」為主，不是「參數有兩個以上就要換行」。
- interface 宣告與其實作（含 Controller Action、Service 方法）都適用同一標準。
- 若既有程式碼本身已用換行風格且未被本次改動觸及，不需要順手修改。

### Rule 6：簡單的陳述式/運算式能放同一行就不要刻意換行

新增/修改的程式碼中，方法呼叫、`return`、三元運算子（`?:`）等單一陳述式，若整行長度沒有超出一般行寬（約 120 字元），就必須寫在同一行，不可為了習慣性排版而拆成多行。只有真的超長（字串很長、巢狀呼叫很多層）才允許換行。

正確範例（放同一行）：
```csharp
return RegularProductResult<PlanQueryResponse>.Failure("此定期購方案不存在，請重新輸入");

int? maxDeliver = product.RpdShipLimitStatus == 1 ? null : product.RpdShipLimitCount;
```

錯誤範例（禁止，短短的內容卻硬拆行）：
```csharp
return RegularProductResult<PlanQueryResponse>.Failure(
    "此定期購方案不存在，請重新輸入");

int? maxDeliver = product.RpdShipLimitStatus == 1
    ? null
    : product.RpdShipLimitCount;
```

要點：
- 判斷標準與 Rule 5 一致：以「是否真的放不下」為主，不是「有參數/有三元運算子就要換行」。
- 若既有程式碼本身已用換行風格且未被本次改動觸及，不需要順手修改。

### Rule 7：新增/修改的方法必須有完整 log 方便追蹤（trace）

新增或修改的 public 方法（尤其是 Service 層跨系統呼叫、有業務分支的邏輯），都必須加上足夠的 log，方便日後排查問題與追蹤呼叫軌跡。

要點：
- **方法進入點**：關鍵方法（涉及外部呼叫、複雜業務邏輯）開頭應加 `LogInformation`，記錄方法名稱與關鍵輸入參數（如 `ShopId`、`PlanId`、`ProductNo` 等業務鍵），格式比照既有慣例：
  ```csharp
  this._logger.LogInformation("QueryProductByPlanAsync 開始，ShopId={ShopId}, PlanId={PlanId}", shopId, planId);
  ```
- **失敗/例外路徑**：查無資料、業務規則不通過、catch 到例外時，應加 `LogWarning`（可預期的業務失敗）或 `LogError`（非預期例外，需帶入 exception 物件），記錄失敗原因與相關業務鍵，方便從 log 直接定位是哪一筆資料出問題。
- **不要過度 log**：單純的欄位組裝、簡單的 getter/setter、無分支的資料轉換不需要額外加 log，避免雜訊淹沒真正需要追蹤的資訊。
- log 訊息格式沿用專案既有慣例（結構化 log，`{PropertyName}` 佔位符 + 對應參數，不要用字串插值 `$"..."` 拼接業務鍵值），與既有程式碼風格一致。

### Rule 8：新增的 .cs 檔案必須確認已加入專案檔（.csproj）

在傳統 .NET Framework（非 SDK-style，`packages.config` 風格）專案中新增檔案（`create` 工具建立新 `.cs` 檔）後，**該檔案不會自動被編譯**，必須手動在對應的 `.csproj` 加上 `<Compile Include="..." />` 項目，否則會在 build 時出現 `CS0246`（找不到型別）等誤導性錯誤，讓人誤以為是命名空間或 using 的問題。

要點：
- 每次用 `create` 工具新增 `.cs` 檔後，**立即**檢查該檔案所屬的 `.csproj`（通常與檔案同目錄或往上找最近的 `.csproj`）是否已有對應的 `<Compile Include="相對路徑\檔名.cs" />`。
- 若專案是 SDK-style（`<Project Sdk="Microsoft.NET.Sdk">` 開頭，通常搭配萬用字元自動收錄 `**/*.cs`），則不需要手動加，但仍建議確認一次專案格式，避免誤判。
- 新增檔案後，**務必實際跑一次 build**（`dotnet build` 或 MSBuild）驗證，不能只憑肉眼檢查程式碼正確就視為完成；若 build 出現 `CS0246` 但程式碼看起來完全正確（using、命名空間都對），優先懷疑是不是漏了 `.csproj` 項目，而不是繼續在程式碼邏輯上打轉。
- 若同一批修改新增了多個檔案，一次把所有新檔案的 `.csproj` 項目都補齊，再統一 build 驗證，避免逐一修正、逐一重跑 build 浪費時間。

## 執行時機

- 每次撰寫或修改 C# 方法時，主動套用 Rule 1、Rule 2、Rule 3、Rule 4，不需使用者每次重複提醒。
- 完成程式碼修改後，若時間允許，可簡短自我檢查一次：新增的方法/欄位是否都有完整註解、新增的 if 是否都有大括號、null 防呆是否足夠。
- 若專案自身的 `.github/instructions` 有更嚴格或更具體的規則（例如額外要求 WHY/EDGE/RISK/VERIFY 標記），兩者一併套用；若專案規則與此 skill 衝突，以使用者當下的明確指示為準，並提醒使用者發現的衝突點。
