# FluentValidation 獨立驗證專案架構決策紀錄

> 案例來源：`nine1.regularpurchase.v2`（定期購 v2 API）新增定期購方案（含贈品活動）功能
> 記錄重點：**為什麼從手寫 if-else 一路演化到獨立 `Common.Validators` 專案**，而不是最終架構本身。

---

## 1. 起點：手寫 if-else 驗證的問題

實作贈品活動規則時，最初的寫法長這樣：

```csharp
private static string? ValidatePromotionRules(List<RegularProductPromotionRule> rules, int shipLimitCount, int shippingSet)
{
    foreach (var rule in rules)
    {
        if (rule.Type != "GIFT")
            return "不支援的活動類型";

        if (rule.TriggerMode != "INTERVAL")
            return "不支援的觸發模式";

        // ... 一路寫下去
    }
    return null;
}
```

判斷此寫法「不好維護」的具體徵兆：

| 徵兆 | 說明 |
|---|---|
| **職責混雜** | 型別檢查、範圍檢查、跨欄位邏輯（shipLimitCount vs interval）全部塞在同一個方法裡 |
| **錯誤訊息硬編碼** | 字串散落在 if 判斷裡，難以統一管理、難以之後做 i18n |
| **規則不可重用** | Add/Edit 兩支 API 未來都要驗證同一組規則，手寫方法無法被組合、繼承 |
| **只回傳第一個錯誤** | 前端沒辦法一次拿到所有欄位的錯誤，只能一次修一個送一次 |
| **擴充成本遞增** | 每多一個欄位就多一個 if，方法會線性變長變醜 |
| **魔術字串** | `"GIFT"`、`"INTERVAL"` 全大寫字串到處比對，容易打錯字且無編譯期檢查 |

**先做的小修正**：先把 `"GIFT"`／`"INTERVAL"` 抽成 `RegularProductPromotionTypeEnum`／`RegularProductPromotionTriggerModeEnum`，
值改用 PascalCase（`Gift`／`Interval`），並讓 `Program.cs` 加上 `JsonStringEnumConverter`，序列化時仍以字串呈現給前端。
enum 只定義「目前真的用到的值」，例如 `TriggerMode` 目前只有 `Interval`，`Sequence` 雖然文件有規劃但沒實作就先不寫進 enum，
避免定義了卻沒有對應邏輯的「假選項」。

---

## 2. 中繼站：抽出 Validator Interface（尚未上 FluentValidation）

在還沒決定要不要導入 FluentValidation 之前，先做了一個**低成本、可逆的過渡**：

```csharp
public interface IRegularProductPromotionRuleValidator
{
    string? Validate(List<RegularProductPromotionRule> rules, int shipLimitCount, int shippingSet);
}
```

把原本的 private static 方法整段搬進 `RegularProductPromotionRuleValidator` 實作類別，
`RegularProductService` 改成建構子注入該 interface。

**這一步的判斷邏輯是什麼？**

- 專案裡完全沒有用過 FluentValidation，貿然導入等於同時做「重構」+「導入新技術」兩件事，風險疊加。
- 先抽 interface，本質上就是在做 **[Extract Class]** 這個最基本的重構手法，
  不改變任何驗證邏輯本身，只是換個地方放，風險趨近於零。
- 如果日後真的要換 FluentValidation，這個 interface 邊界剛好就是「手寫版」與「FluentValidation 版」
  唯二的替換點：`RegularProductService` 完全不用改。
- 也就是說，這一步是刻意留給未來反悔空間的「便宜的可逆決策」（reversible decision）。

---

## 3. 關鍵轉折：使用者主動提出「不如直接上 FluentValidation」

當看到自己親手抽出的 `IRegularProductPromotionRuleValidator` 介面後，
使用者反問：「感覺這樣抽了一個 validator interface，是不是我乾脆就用 FluentValidation 就好？」

**判斷依據（為什麼答案是「對，該換了」）：**

1. 手寫 interface 版本本質上就是在**山寨 FluentValidation 已經做好的東西**——
   `IValidator<T>`、`ValidationResult`、規則組合能力，FluentValidation 全部都有現成、久經考驗的實作。
2. 專案已經確定要往「驗證規則要能被組合、要能被多個 Request 共用」的方向走，
   這正是 FluentValidation 的核心設計目的（`RuleFor`／`RuleForEach`／`SetValidator`／`Include`）。
3. 手寫版本要達到「收集所有錯誤」「跨欄位驗證」「條件式驗證（`When`）」都得自己刻，
   FluentValidation 語法本身就是宣告式地表達這些情境。
4. 換的時機點很重要：**現在專案還小、只有一個 Validator、一個消費者**，
   換掉的代價最低；等到規則越長越多，屆時再換就是大規模重構。

**結論**：不是「要不要上 FluentValidation」的技術偏好問題，而是「現在手寫的東西已經摸到了
FluentValidation 想解決的問題邊界」，繼續手刻等於重新發明輪子。

---

## 4. 設計決策：驗證整個 Request，而不是只驗證 PromotionRule

使用者進一步提出：「應該是要驗證整個 AddRequest，AddRequest 裡面也跑 PromotionRule 的 validator」。

**為什麼這個決定是對的：**

- 原本 Service 內部除了 `ValidatePromotionRules`，其實還有一堆手動 if
  （`ProductShippingPeriod.Count < 1`、`ShopId <= 0`、`ProductShippingMax` 範圍等），
  這些跟 PromotionRule 驗證邏輯性質相同，只是驗證對象不同。
- 如果只把 PromotionRule 抽出來換 FluentValidation，其餘欄位驗證還是手寫 if，
  等於同一支 API 有兩套驗證風格並存，維護心智負擔沒有真正下降。
- FluentValidation 天生支援「一個 Validator 驗證整個物件、子物件用 `RuleForEach(...).SetValidator(...)`
  委派給子 Validator」的組合模式，剛好對應 `ProductAddRequest` 裡有一個 `List<RegularProductPromotionRule>`
  的巢狀結構。

**於是設計出兩層 Validator：**

```
ProductAddRequestValidator : AbstractValidator<ProductAddRequest>
    ├─ RuleFor(ShopId) / ProductNo / ProductShippingPeriod / ProductShippingSet / Max / Fixed
    └─ RuleForEach(RegularProductPromotionRules)
            .SetValidator((request, _) => new RegularProductPromotionRuleValidator(
                ComputeShipLimitCount(request), request.ProductShippingSet))
                ├─ RegularProductPromotionRuleValidator : AbstractValidator<RegularProductPromotionRule>
                │       └─ RuleForEach(RegularProductPromotionGiftItemList)
                │               .SetValidator(new RegularProductPromotionGiftItemValidator())
                └─ RegularProductPromotionGiftItemValidator : AbstractValidator<RegularProductPromotionGiftItem>
```

**跨欄位參數傳遞的技術難題與判斷：**

`RegularProductPromotionRuleValidator` 需要知道「這個 Rule 所屬的 Request 有沒有配送次數限制
（shipLimitCount）、限制模式（shippingSet）」，這兩個值不屬於 Rule 自己，而是父層 Request 的欄位。

- 若讓 `RegularProductPromotionRuleValidator` 走 DI 單例／無參數建構子，就拿不到這兩個上下文值。
- 解法是使用 FluentValidation 提供的 `SetValidator(Func<TParent, TChild, IValidator<TChild>>)` overload，
  每次驗證時用當下的 `request` 動態 `new` 一個帶參數的子 Validator 實例。
- 這代表 `RegularProductPromotionRuleValidator` **不適合被 DI 批次註冊為服務**
  （建構子有必填參數，`AddValidatorsFromAssembly` 若嘗試 resolve 它會找不到無參數建構子），
  但這完全沒關係，因為它從來不會被單獨當作服務注入，永遠是被 `ProductAddRequestValidator` 動態建立的。
- 真正走 DI 的只有最外層的 `IValidator<ProductAddRequest>`（也就是 `ProductAddRequestValidator`，
  它的建構子沒有外部依賴，可以安全走 `AddValidatorsFromAssembly` 批次註冊）。

**錯誤訊息聚合策略（本次刻意不做的事）：**

FluentValidation 的 `ValidationResult.Errors` 天生可以收集全部錯誤，但 Controller 現有的
`MessageApiResponseEntity<object>.Message` 是單一字串設計。這次的範圍決定是：
**先只取 `Errors[0].ErrorMessage`**，維持與既有行為相容，把「一次回傳所有錯誤」列為之後才做的需求變更，
避免這次重構同時夾帶行為變更，混淆問題範圍。

---

## 5. 要不要拆成獨立專案？

抽出 `ProductAddRequestValidator` 之後，下一個問題是：Validator 要放在既有的 `BL.Services` 裡，
還是拆一個全新的 `Nine1.Regularpurchase.V2.Common.Validators` 專案？

**先盤點公司既有慣例**：grep 了 `Nine1.Promotion`／`Nine1.Cart`／`Nine1.Coupon`／`Nine1.Shopping`
等多個既有專案，發現它們全部都採用「獨立 `Xxx.Common.Validators` 專案」的模式，
套件版本統一為 `FluentValidation 11.5.1` + `FluentValidation.DependencyInjectionExtensions 11.5.1`，
透過 `services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly())` 做組件層級批次註冊。

**拆或不拆的權衡：**

| 面向 | 放在 BL.Services | 拆獨立 Common.Validators |
|---|---|---|
| 依賴方向 | Validator 與 Service 混在一起，職責邊界模糊 | Validator 只依賴 BE（DTO），依賴方向單純、清楚 |
| 可測試性 | 需要連帶 Service 的其他依賴才能測 | 可以獨立單元測試，不需要 mock Repository/外部服務 |
| 可重用性 | 只有 Service 能用 | 未來若有其他消費者（如 Console Job、其他 API）也能引用 |
| 符合公司慣例 | 否 | 是（與 Promotion/Cart/Coupon/Shopping 一致） |
| 建置成本 | 無 | 多一個 csproj、需要加入 .sln、多一層 ProjectReference |
| 現況規模 | 目前只有一個消費者（RegularProductService） | overhead 在現階段規模下略顯「殺雞用牛刀」 |

**最初的建議是「規模還小，先不拆」**，但使用者的判斷推翻了這個保守建議：

> 「我覺得趁現在還小的時候大家比較敢改專案，應該現在就拆成獨立 validators 專案！」

**這個判斷背後的道理**：專案結構調整的阻力，會隨著程式碼量、依賴數量、
既有消費者數量增加而遞增。現在只有一個 Validator、一個呼叫端，
搬移的成本是「新建 csproj + 改幾個 using」等級；等到規則寫多了、
被多個 Service 依賴了，屆時要抽專案就會牽動一大片改動，
且會有人怕改壞既有功能而不敢動。**越早拆，沉沒成本越低**，
這是比「當下 overhead 大小」更重要的判斷因子。

---

## 6. 最終落地的整合方式

1. 新建 `Nine1.Regularpurchase.V2.Common.Validators` 專案（`net10.0`），
   只 `ProjectReference` `BL.BE`（因為 Validator 只需要認得 DTO 定義，不該依賴 Service/Repository）。
2. 專案內建立 `Extensions/ServiceCollectionExtension.cs`，提供
   `AddRegularPurchaseValidators()` 擴充方法，內部呼叫 `AddValidatorsFromAssembly(Assembly.GetExecutingAssembly())`，
   讓組件內所有 `AbstractValidator<T>` 一次批次註冊，之後新增 Validator 不需要手動一個個加 DI 註冊。
3. `RegularProductService` 建構子改注入 FluentValidation 標準介面 `IValidator<ProductAddRequest>`，
   刪除原本錯誤指向已淘汰類別的 `IRegularProductPromotionRuleValidator`。
4. `AddProductAsync` 開頭統一呼叫 `await _addRequestValidator.ValidateAsync(request)`，
   **取代**掉純欄位規則的手動 if（`ValidateShipLimitInput`、`ProductShippingPeriod.Count < 1` 等）；
   但 SCM 商品查詢、`ExistsByProductAsync`、生效區間 Overlap 檢查等**依賴 DB／外部服務**的規則，
   刻意保留在 Service 內，不塞進 Validator——因為 FluentValidation 的職責應該侷限在
   「物件自身欄位、跨欄位的靜態規則」，不該承擔 I/O 依賴，否則 Validator 會變得難以單獨測試。
5. `Web.Api` 的 `ServiceCollectionExtension.cs` 移除舊的手動 `AddScoped<IRegularProductPromotionRuleValidator, ...>()`，
   改呼叫新專案提供的 `AddRegularPurchaseValidators()`。
6. `.sln` 手動 `dotnet sln add` 加入新專案；`BL.Services`／`Test` 專案的 `.csproj` 補上對應 `ProjectReference`。

---

## 7. 這次決策過程可以抽象出的通則

1. **先做便宜的可逆重構，再做貴的技術選型**：抽 interface（Extract Class）幾乎零風險，
   卻剛好幫你把「要不要換 FluentValidation」的決策邊界清楚劃出來，降低了後面反悔的成本。
2. **當手寫程式碼開始模擬某個現成函式庫的核心概念時，就是該換函式庫的訊號**——
   自己刻的 `IValidator`/`Validate()` 幾乎就是 FluentValidation 的縮水版。
3. **驗證的邊界應該對齊「物件」而非「欄位片段」**：只驗證 PromotionRule、
   不驗證整個 Request，會讓同一支 API 內存在多套驗證風格；
   驗證應該以「這支 API 收到的完整輸入物件」為單位設計。
4. **跨欄位依賴不該逼子 Validator 走 DI 單例**：用 `SetValidator(Func<parent, child, IValidator<child>>)`
   在驗證當下動態建構子 Validator，是 FluentValidation 處理「子物件驗證需要父物件上下文」的標準手法。
5. **拆專案的時機看「未來改動阻力」，不是看「當下 overhead」**：
   規模小的時候拆分專案的邊際成本最低，此時最適合對齊公司既有的架構慣例。
6. **不要讓一次重構同時夾帶行為變更**：本次維持「只回傳第一個錯誤」不變，
   把「聚合全部錯誤回傳前端」留給未來獨立的需求變更，避免混淆這次重構的驗收範圍。
7. **Validator 只管靜態規則，I/O 依賴留在 Service**：讓 Validator 保持純粹、
   可以脫離資料庫與外部服務單獨做單元測試，是长期可維護性的關鍵界線。

---

## 8. 最終驗證結果

- `dotnet build`（整個 solution）：Build succeeded，0 Error。
- `dotnet test --filter RegularProduct`：20/20 全數通過。

---

## 9. Debug 紀錄

### 9.1 問題現象

專案啟動（`dotnet run`）時，尚未接到任何 Request，就直接拋出未處理例外：

```
Exception has occurred: CLR/System.AggregateException
An unhandled exception of type 'System.AggregateException' occurred in
Microsoft.Extensions.DependencyInjection.dll: 'Some services are not able to be constructed'

Innermost exception:
System.InvalidOperationException : Unable to resolve service for type 'System.Int32'
while attempting to activate
'Nine1.Regularpurchase.V2.Common.Validators.RegularProduct.RegularProductPromotionRuleValidator'.
```

### 9.2 根因分析

`ServiceCollectionExtension.AddRegularPurchaseValidators()` 呼叫的是：

```csharp
services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
```

`AddValidatorsFromAssembly` 的預設行為是：**掃描整個組件，把每一個 `AbstractValidator<T>` 都當作服務註冊進 DI 容器**。

問題出在 `RegularProductPromotionRuleValidator` 的建構子：

```csharp
public RegularProductPromotionRuleValidator(int shipLimitCount, int shippingSet)
```

這兩個 `int` 參數是**驗證當下**才從 `ProductAddRequest` 動態計算出來的上下文值（配送次數上限、配送次數模式），
根本不是可以預先注入 DI 容器的「服務」。ASP.NET Core 在應用程式啟動時做 DI 容器驗證
（`ServiceProvider.ValidateService`），嘗試為這個類別解析建構子參數，找不到 `System.Int32`
對應的已註冊服務，於是在啟動階段直接丟出例外，App 起不來。

**這其實是在第 4 章設計「跨欄位參數傳遞」時就已經預先標注過的風險點**：
> 「這代表 `ProductAddRequestValidator` 本身雖然可以走 DI singleton／scoped 沒問題，
> 但 `RegularProductPromotionRuleValidator` 因為建構子有參數，不適合單獨註冊為 DI service
> ——這點尚未驗證，是潛在風險點」

這次啟動專案時，風險正式兌現。

### 9.3 為什麼它本來就不該被 DI 管理

`RegularProductPromotionRuleValidator` 從設計上**永遠不會被單獨當作服務注入**，
它只會被 `ProductAddRequestValidator` 用以下方式在驗證當下動態建立：

```csharp
this.RuleForEach(x => x.RegularProductPromotionRules)
    .SetValidator((request, _) => new RegularProductPromotionRuleValidator(
        ComputeShipLimitCount(request), request.ProductShippingSet));
```

也就是說，真正需要走 DI 的只有最外層的 `IValidator<ProductAddRequest>`
（即 `ProductAddRequestValidator`，它的建構子沒有外部依賴，可以安全走 DI）。

### 9.4 修復方式

利用 FluentValidation 官方提供的 `AddValidatorsFromAssembly(assembly, filter: ...)` overload，
在批次掃描時明確排除這一個類別，不讓它進入 DI 容器：

```csharp
public static void AddRegularPurchaseValidators(this IServiceCollection services)
{
    services.AddValidatorsFromAssembly(
        Assembly.GetExecutingAssembly(),
        filter: scanResult => scanResult.ValidatorType != typeof(RegularProductPromotionRuleValidator));
}
```

**修法的判斷依據：**

- 只排除「這一個」有問題的類別，其餘 `ProductAddRequestValidator`／`RegularProductPromotionGiftItemValidator`
  建構子都沒有外部參數，繼續正常走批次自動註冊，行為不變。
- 不動任何業務驗證邏輯——純粹是 DI 註冊層面的排除，`RegularProductPromotionRuleValidator` 的規則、
  `ProductAddRequestValidator` 呼叫它的方式（`SetValidator` 動態 `new`）完全沒改。
- `filter` 是 FluentValidation 公開 API 的正規用法，不是反射 hack 或繞過機制。

### 9.5 驗證結果

- `dotnet build`（整個 solution）：Build succeeded，0 Error。
- `dotnet run` 實際啟動 `Web.Api`：不再拋出 `AggregateException`，Kestrel 成功綁定埠、服務正常啟動。

### 9.6 延伸提醒（既有設計限制，非本次引入）

未來如果再新增其他「建構子帶參數」的 Validator（例如 Edit API 若也需要類似跨欄位動態驗證），
也必須一併加進這個 `filter` 排除清單，否則會重複踩到同樣的啟動期例外。
若這類 Validator 數量增加，可以考慮改用「白名單只註冊無依賴的 Validator」或加上 marker interface
來做更明確的區分；但目前只有一個特例，用排除法已足夠且最小侵入。

---

### 9.7 VS Code 找不到 HK-Dev / TW-Dev / MY-Dev 啟動選項

**問題現象**：專案 `launchSettings.json` 裡明明已經定義好 `TW-Dev`／`HK-Dev`／`MY-Dev` 三個 profile
（各自對應不同的 `N1_MARKET` 環境變數），但在 VS Code 的「執行與偵錯」面板上方下拉選單，
只看得到 `C#: Debug Active File`、`Node.js…`、`Docker: Build…` 等 VS Code 原生 debugger 類型，
完全找不到這三個自訂 profile，導致每次啟動都只能用預設值（結果就是一直落在 TW-QA）。

**根因分析**：`launchSettings.json` 與 `.vscode/launch.json` 是兩個各自獨立的系統：

| 檔案 | 誰在讀 | 作用 |
|---|---|---|
| `Properties/launchSettings.json` | `dotnet run`、Visual Studio、VS Code C# 擴充 | 定義「profile」——一組環境變數 + URL 設定的集合 |
| `.vscode/launch.json` | 只有 VS Code 的 Debug 面板 | 定義「VS Code 看得懂的 debug configuration」，需要**自己手動指定**要對應哪個 profile |

`launchSettings.json` 裡定義的 profile **不會自動**變成 VS Code Debug 面板下拉選單的選項；
Visual Studio 有這種自動對應行為，但 VS Code 沒有——兩者中間必須靠使用者自己在
`.vscode/launch.json` 裡手動建立一筆對應設定，VS Code 才認得。

**解法**：在 `.vscode/launch.json` 的 `configurations` 陣列裡，針對每個想要的 profile 各自新增一筆設定，
用新版 C# Dev Kit 支援的 `"type": "dotnet"` + `profileName` 屬性直接對應到 `launchSettings.json` 的 profile
（不需要重複抄一次環境變數）：

```json
{
    "configurations": [
        {
            "name": "C#: Debug Active File",
            "type": "dotnet",
            "request": "launch",
            "projectPath": "${file}"
        },
        {
            "name": "TW-Dev",
            "type": "dotnet",
            "request": "launch",
            "projectPath": "${workspaceFolder}/src/Web/Nine1.Regularpurchase.V2.Web.Api/Nine1.Regularpurchase.V2.Web.Api.csproj",
            "profileName": "TW-Dev"
        },
        {
            "name": "HK-Dev",
            "type": "dotnet",
            "request": "launch",
            "projectPath": "${workspaceFolder}/src/Web/Nine1.Regularpurchase.V2.Web.Api/Nine1.Regularpurchase.V2.Web.Api.csproj",
            "profileName": "HK-Dev"
        },
        {
            "name": "MY-Dev",
            "type": "dotnet",
            "request": "launch",
            "projectPath": "${workspaceFolder}/src/Web/Nine1.Regularpurchase.V2.Web.Api/Nine1.Regularpurchase.V2.Web.Api.csproj",
            "profileName": "MY-Dev"
        }
    ]
}
```

**欄位意義**：

- `name`：顯示在下拉選單的名字，可任意取，不需要跟 profile 同名
- `type`：固定寫 `dotnet`（新版 C# Dev Kit 的 debugger 型別；舊版 `coreclr` 不支援 `profileName`，需要自己手動整包複製 `environmentVariables`）
- `projectPath`：指向要啟動的 `.csproj`，可用 `${workspaceFolder}` 相對表示
- `profileName`：⭐ 關鍵欄位，對應 `launchSettings.json` 裡的 profile 名稱，**必須逐字一致（含大小寫）**

存檔後執行 `Ctrl+Shift+P` → `Reload Window`，重新整理 VS Code 視窗，Debug 面板下拉選單即可看到新選項。

**常見踩雷點**：

1. `profileName` 打錯字或大小寫不符——VS Code 不會跳出錯誤提示，只會悄悄套用預設環境變數啟動，容易誤以為切換失敗
2. 改完 `launch.json` 忘記 Reload Window——下拉選單顯示的仍是舊清單
3. `type` 誤用舊版 `coreclr`——這個型別沒有 `profileName` 屬性，必須手動把 `environmentVariables` 整包複製過去
4. Solution 根目錄的 `.vscode/launch.json`，`projectPath` 一定要指到具體 `.csproj`，不能只給資料夾路徑

**備援方案（不依賴 VS Code UI）**：即使不想動 `launch.json`，也可以直接在終端機用 `--launch-profile` 參數指定：

```powershell
cd C:\91APP\regular\api\nine1.regularpurchase.v2\src\Web\Nine1.Regularpurchase.V2.Web.Api
dotnet run --launch-profile HK-Dev
```

---

### 9.8 呼叫 API 時收到 `"ErrorMessage": "No authorized."`

**問題現象**：本機啟動專案後，用 REST Client / Postman 呼叫 `POST /api/regular/products`，
沒有進到 Controller 的任何驗證邏輯（連 `ShopId <= 0` 這種最前面的檢查都沒觸發），
直接收到統一格式的失敗回應：

```json
{
  "Status": "Failure",
  "TxId": "d5dc866684b04efabe2e94826feb2dc2",
  "Data": null,
  "ErrorMessage": "No authorized."
}
```

**根因分析**：這支 API 有一個全域 `ApiKeyAuthMiddleware`，攔截所有 `/api/*` 路由，
在進入 MVC pipeline（Controller/FluentValidation）之前就先做驗證：

```csharp
private const string ApiKeyHeaderName = "x-api-key";

if (context.Request.Path.StartsWithSegments("/api", StringComparison.OrdinalIgnoreCase))
{
    if (context.Request.Headers.TryGetValue(ApiKeyHeaderName, out var apiKey) == false
        || apiKey.ToString() != this._validApiKey)
    {
        // 直接回傳 "No authorized."，不會呼叫 next()，Controller 完全不會被執行
    }
}
```

- 這個 Middleware 是對應 V1 PHP 的 `check_api_key()`，比對 Request Header 裡的 `x-api-key`
  與設定檔 `_N1SECRETS:RegularPurchase:ApiGbXApiKey` 的值是否完全相符。
- 這把 Key **依市場（TW/HK/MY）各自不同**，實體檔案在
  `src\Web\Nine1.Regularpurchase.V2.Web.Api\config\secrets.{Market}-QA.json` 底下的
  `RegularPurchase.ApiGbXApiKey`。
- 因為驗證發生在 Middleware pipeline 最前面，不符合就直接短路回應、`await next(context)` 不會被呼叫，
  所以完全不會進到 Controller，也就是為什麼「連最前面的 `ShopId <= 0` 檢查都沒有反應」的原因——
  這不是驗證邏輯或 FluentValidation 的問題，是還沒進到那一層。

**修復方式**：Request 加上 `x-api-key` Header，值取自「目前啟動市場」對應的 secrets 檔案：

```http
POST {{baseUrl}}/api/regular/products
x-api-key: {{apiKey}}
Content-Type: application/json

{ ... }
```

並依此規範建立了可重複使用的 `RegularProduct.http`（REST Client 格式），
把 `baseUrl`／`apiKey`／`shopId` 等都抽成頂端變數，避免每次測試手動改 Header。

**常見踩雷點**：

1. **跨市場誤用 Key**——例如目前用 `HK-Dev` 啟動服務，卻拿 TW 的 `ApiGbXApiKey` 去打，
   一樣會收到 `"No authorized."`，因為 Middleware 是逐字元比對，不會做任何市場自動判斷。
2. **Header 名稱大小寫**——`x-api-key` 這個 Header 名稱本身雖然 HTTP 標準上不分大小寫，
   但要注意是打在 Header 欄位，不是 Query String 或 Body 參數。
3. **這個驗證跟 FluentValidation 是完全不同層級**——`x-api-key` 檢查在 Middleware pipeline，
   會在 FluentValidation（`IValidator<ProductAddRequest>`）跑之前就先擋下，兩者互不影響、
   也不能互相取代；除錯時要先排除「根本沒過 API Key 關卡」這個可能性，再往下查驗證邏輯本身。

### 9.9 為 AddProductAsync 全路徑補 Log，並把驗證時機從 Service 搬到全域 Action Filter

**動機**：原本 `RegularProductService` 為了驗證 `ProductAddRequest`，建構子必須注入
`IValidator<ProductAddRequest>`；可以預期未來每多一支需要 FluentValidation 的 API，
Service 建構子就要多塞一個 `IValidator<TRequest>`，讓「業務邏輯」與「驗證」的依賴混在一起，
建構子會越長越肥，且驗證發生的時機（Service 方法內部第一行）也不夠早——理想上應該是
「Request 一進 Controller 就先擋掉不合法的資料，Service 完全不用管驗證」。

**方案選擇**：評估了三種讓驗證更早發生的作法：

| 方案 | 做法 | 取捨 |
|---|---|---|
| A. 全域 Action Filter（採用） | 寫一個 `IAsyncActionFilter`，攔截所有 Action，反射找出參數對應的 `IValidator<T>` 並執行 | 一次性建置，新增 Request 的驗證完全不用碰 Filter 本身，也不用碰 Service |
| B. Controller 內手動呼叫 | 在每個 Action 自己注入 `IValidator<TRequest>` 呼叫 `ValidateAsync` | 直覺但每支 API 都要複製貼上樣板碼，隨 API 數量增加而重複 |
| C. 整合進 MVC ModelState / 自訂 ValidationVisitor | 讓 FluentValidation 掛進 ASP.NET Core 內建模型驗證流程 | 官方已不建議此整合方式，較舊、較複雜，故不採用 |

最終採用 **方案 A**，理由：職責分離最乾淨（驗證是橫切關注點，不該跟業務邏輯或 Controller 樣板碼綁在一起），
且完全符合「新增 Validator 就自動生效」的擴充性需求。

**實作方式**：

```csharp
// Web.Api/Filters/ValidationActionFilter.cs
public class ValidationActionFilter : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        foreach (var argument in context.ActionArguments.Values)
        {
            if (argument == null) continue;

            // 依「參數的實際型別」動態組出 IValidator<T>，向 DI 容器查詢是否有註冊
            var validatorType = typeof(IValidator<>).MakeGenericType(argument.GetType());
            var validator = context.HttpContext.RequestServices.GetService(validatorType) as IValidator;

            if (validator == null) continue; // 沒有對應 Validator，代表這個 Request 不需要驗證，放行

            var result = await validator.ValidateAsync(new ValidationContext<object>(argument));
            if (result.IsValid) continue;

            // 驗證失敗：直接短路回傳，Controller Action 完全不會被執行
            context.Result = new OkObjectResult(new MessageApiResponseEntity<object>
            {
                Status = "Failure",
                Data = null,
                Message = result.Errors[0].ErrorMessage,
            });
            return;
        }

        await next();
    }
}
```

```csharp
// Program.cs
builder.Services.AddControllers(options =>
{
    options.Filters.Add<ValidationActionFilter>();
});
```

同步把 `RegularProductService` 建構子的 `IValidator<ProductAddRequest> addRequestValidator` 參數整個移除，
`AddProductAsync` 方法內也拿掉手動 `ValidateAsync` 呼叫，只保留一句註解說明驗證已交給 Filter 處理。

**自動生效的機制與前提**：

這個機制能「加了 Validator 就自動生效、不用改其他程式碼」，關鍵在於兩件事同時成立：

1. **有寫 Validator 類別**——繼承 `AbstractValidator<TRequest>`，放在
   `Nine1.Regularpurchase.V2.Common.Validators` 專案底下（例如 `ProductAddRequestValidator : AbstractValidator<ProductAddRequest>`）。
2. **有被註冊進 DI**——這步是關鍵，靠的是既有的：
   ```csharp
   services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly(), filter: ...);
   ```
   這行會**自動掃描整個 Assembly**，把所有 `AbstractValidator<T>` 的實作都註冊成 `IValidator<T>`。
   `ValidationActionFilter` 只是在執行期用參數型別去問 DI 容器「有沒有人幫我註冊過 `IValidator<這個型別>`」，
   有的話就跑、沒有就放行——**Filter 本身完全不知道、也不需要知道有哪些 Request 型別存在**。

因此，只要之後新增一個 `XxxRequestValidator : AbstractValidator<XxxRequest>` 丟進
`Common.Validators` 專案，**不需要改 `Program.cs`、不需要改 Filter、不需要改 Service**，
下次呼叫對應 API 時就會自動被攔截驗證。

**不會自動生效的例外情況**：

1. **Validator 建構子帶有無法被 DI 解析的參數**——例如 `RegularProductPromotionRuleValidator`
   建構子吃 `(int shipLimitCount, int shippingSet)`，這種已在 `AddRegularPurchaseValidators`
   的 `filter` 裡明確排除，不會被自動掃描註冊，也就**不會**被 `ValidationActionFilter` 攔截到
   （它本來就不是設計給 Action 參數直接用的 Validator，而是由 `ProductAddRequestValidator`
   透過 `RuleForEach(...).SetValidator((request, _) => new RegularProductPromotionRuleValidator(...))`
   在驗證當下動態建立、傳入額外上下文參數）。
2. **Validator 寫在 `Common.Validators` 專案以外的地方**——`AddValidatorsFromAssembly` 只掃描
   「這一個」組件；如果之後有其他專案想加 Validator，要嘛也把 Validator 放進這個組件，
   要嘛要在 `ServiceCollectionExtension.AddRegularPurchaseValidators` 裡多補一行掃描新的 Assembly。
3. **多個 Action 參數且型別重複**——目前專案內每個 Request 型別只對應唯一一個 Validator，
   若未來某個 Action 同時有多個參數且各自都有 Validator，Filter 會依序驗證、遇到第一個失敗就短路回傳，
   尚未有回傳「多個參數的所有錯誤」的需求，暫不處理。

**全路徑 Log 補充**：同一輪也在 `RegularProductController.AddProductAsync`（收到請求／驗證失敗／處理失敗／成功）
與 `RegularProductService.AddProductAsync`（各個業務規則失敗分支、儲存失敗、成功）補上對應的
`ILogger` 記錄，並確認 `ProductAddRequestValidator` 可以安全注入 `ILogger<ProductAddRequestValidator>`
（框架內建服務，DI 可解析，跟 9.1~9.6 提到的「建構子吃 int 而炸掉」是完全不同性質），
在 `PreValidate` override 裡記錄「這次是誰進來驗證、關鍵欄位是什麼」，方便對照 log 追蹤。

**驗證結果**：`dotnet build`（整個 solution）：Build succeeded，0 Error；
`dotnet test --filter RegularProduct`：20/20 通過。

**順手清理**：同一輪也移除了 `RegularProductController.AddProductAsync` 裡重複的
`ShopId <= 0 || ProductNo <= 0` 手動檢查（因為 `ProductAddRequestValidator` 本來就有
`RuleFor(x => x.ShopId).GreaterThan(0)` 等同的規則），避免同一份錯誤訊息分散在
Controller 與 Validator 兩處、未來改字未同步的風險；`GetListAsync`／`ValidateProductAsync`／
`QueryProductAsync` 這幾支目前沒有走 FluentValidation 的 API，維持原本手動檢查不動。

### 9.10 補齊遺漏的欄位驗證規則，並把 AddProductAsync 商品頁驗證抽成共用方法

**問題現象**：逐一比對 `ProductAddRequestValidator` 與 `RegularProductService.AddProductAsync`
後發現，需求文件提到的以下規則完全沒有做檢查：

- `ProductPurchaseOption`：應限制只能是 `1`（僅定期購）或 `2`（定期購+一次性）
- `PlanTitle`：全形、半形混合文字上限 20 字；若皆為半形文字，上限 40 字
- `PlanDateBegin`：生效開始時間須晚於現在時間 10 分鐘以上
- `PlanDateEnd`：生效結束時間須晚於生效開始時間
- 生效期間 vs 商品銷售期間：生效開始時間不得早於商品銷售開始時間，生效結束時間不得晚於商品銷售結束時間

**處理方式**：

1. 前 4 條屬於「純欄位／跨欄位」規則，不需查外部資料，補進 `ProductAddRequestValidator`：
   - `PlanTitle` 用字元 code point 是否 `> 0xFF` 判斷全形／半形，決定 20/40 字上限
   - `PlanDateBegin`/`PlanDateEnd` 透過注入 `TimeProvider` + `DateTimeHelper.GetNow(...)` 取得目前時間比較
   - `ProductPurchaseOption` 用 `Must(option => option is 1 or 2)`
2. 最後一條「生效期間 vs 商品銷售期間」需要 SCM 回傳的 `SellingStartDateTime`/`SellingEndDateTime`，
   FluentValidation 目前設計是同步、無 I/O 的規則集合，無法在 Validator 內取得，改採方案 A：
   維持在 Service 層、拿到 `salePageData` 後立刻檢查，與既有「商品序號已存在」等其他依賴外部
   資料的規則位置一致，是最小侵入的做法。
3. `Common.Validators.csproj` 因此新增對 `Common.Utils` 的 ProjectReference（取得
   `DateTimeHelper`），並把 `Microsoft.Extensions.Logging.Abstractions` 從 9.0.0 升到 10.0.0，
   解決因此新增依賴帶來的 NU1605 套件降版衝突（`Common.Utils` 透過
   `Microsoft.Extensions.Caching.Memory` 間接要求 `Logging.Abstractions >= 10.0.0`）。

**抽出 `ValidateSalePageDataForAddAsync` 共用方法**：`AddProductAsync`（新增流程）與
`EditProductAsync`（編輯流程）原本各自重複了「`salePageData == null` → `ShippingTypeDef`
不是定期購 → `HasPointsPayPairs`」這三段幾乎相同的商品頁檢查。抽成：

- `ValidateSalePageData(salePageData)`：純同步 helper，只包這三段共用檢查，
  `AddProductAsync`／`EditProductAsync` 都會呼叫
- `ValidateSalePageDataForAddAsync(salePageData, request)`：**只給 `AddProductAsync` 用**，
  內部先呼叫上面的共用 `ValidateSalePageData`，再串接「新增流程」才有的三項檢查：
  生效期間 vs 商品銷售期間、商品序號已存在（`ExistsByProductAsync`）、
  生效期間重疊（`ExistsOverlappingPlanAsync`）

**為什麼生效期間檢查不能也讓 `EditProductAsync` 共用**：`ProductEditRequest` 這個 Request
型別本身就沒有 `PlanDateBegin`/`PlanDateEnd` 欄位（grep 確認無結果），代表編輯流程本來就
不會異動生效期間、沿用既有設定，這條規則在語意上就只屬於「新增」這個動作，因此刻意
**不**放進兩邊都共用的 `ValidateSalePageData`，避免共用方法簽章被迫塞進只有一邊會用到的參數。

**驗證結果**：`dotnet build`（BL.Services 專案 + 整個 solution）：Build succeeded，0 Error，
且抽出共用方法後用 `salePageData!`（null-forgiving，改名 `validatedSalePageData`）取代
原本每次都重複判斷 null 的寫法，確認沒有新增 CS8602 可能為 null 解參考警告；
`dotnet test --filter RegularProduct`：20/20 通過。`EditProductAsync` 本身這一輪未變動。

### 9.11 疑問：帶入非法 enum 字串（如 `"type": "fefewf"`）為什麼只回傳籠統的 `"Invalid Data"`？

**問題現象**：實際打 API 測試時，把 `Type`、`GiftTypeId` 這類欄位帶入不存在的字串
（如 `"fefewf"`、`"yyy"`），API 沒有進到 `ProductAddRequestValidator` 或
`RegularProductService`，而是直接回傳：

```json
{
  "Status": "Failure",
  "TxId": "c8c6f690237c44b7adabd0eb69985992",
  "Data": null,
  "ErrorMessage": "Invalid Data"
}
```

一開始以為是 Validator 沒抓到，或 `ValidationActionFilter` 沒生效。

**根因分析**：`Type`、`GiftTypeId` 這兩個欄位在 Request Entity 上是 **enum 型別**，
搭配 `Program.cs` 裡註冊的 `JsonStringEnumConverter`（以 PascalCase 字串序列化，例如
`Type = "Gift"`）。整個請求處理順序是：

1. ASP.NET Core 收到 Request body → 先做 **Model Binding**（JSON 反序列化成
   `ProductAddRequest`）
2. `"fefewf"`／`"yyy"` 這種字串**無法轉換成合法的 enum 值**（enum 只接受定義好的成員名稱），
   反序列化在這一步就直接失敗
3. 反序列化失敗 → 因為是 `[ApiController]`，框架自動判斷該屬性 **ModelState 無效**，
   並在 Action 執行前（比 `ValidationActionFilter`、Controller Action、Service 都還早）
   呼叫 `Program.cs` 裡設定的 `options.InvalidModelStateResponseFactory`
4. 這個 factory 是刻意為了對齊 V1 行為而寫的（見 `Program.cs` 第 24~38 行註解）：
   V1 對「JSON 型別轉換失敗」或「缺少必填欄位」一律回傳 HTTP 200
   `Status=Failure, ErrorMessage="Invalid Data"`，而不是 HTTP 400 validation error，
   所以訊息才會這麼籠統，看不出是哪個欄位、哪個值不合法

**結論**：這是**刻意設計、對齊 V1 行為**的結果，不是 bug，也不是
`ValidationActionFilter`／`ProductAddRequestValidator` 沒生效——因為 Model Binding
失敗發生在更早的階段，這兩者根本沒有機會被執行到。

**延伸提醒（除錯優先順序）**：日後遇到「Request 帶了看起來合理的值，但 API 直接回籠統的
`Invalid Data`，且 Validator/Service 裡設的 Log 完全沒印出來」時，第一步應該先檢查
**該欄位是否為 enum／int／DateTime 等非 nullable 型別、且傳入值是否真的能被反序列化**，
而不是急著去查 Validator 邏輯或 Service 業務規則——因為 Model Binding 失敗這一關
比 Filter、Validator、Service 都早發生，會直接短路掉後面所有的驗證與 Log。
若之後想讓這類錯誤訊息更明確（例如標出是哪個欄位、哪個值不合法），需要另外調整
`InvalidModelStateResponseFactory` 的實作，但這會偏離目前刻意對齊 V1 簡化訊息格式的設計，
需要事先確認是否要改變此行為。
