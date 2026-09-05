---
name: check-test-shop-switch-enable
description: >
  當使用者表達「開啟某功能」、「關閉某設定」、「組開關語法」、「啟用/停用 ShopStaticSetting」、「新增商店設定」等意圖時，使用此 skill。
  在產生 ShopStaticSetting 的 INSERT SQL 前，先確認對應區域的測試店是否已有相同設定，若無則拋出警告，要求測試店先設定並測試完畢。
---

# Check Test Shop Before Toggle Skill

> 此 Skill 適用於 **`C:\91APP\DB\operation`** 專案。
> 針對 `WebStoreDB.dbo.ShopStaticSetting` 的開關類 INSERT 操作，
> 在產生正式商店 SQL 前，強制確認對應區域測試店已有相同設定。

---

## 測試店清單

| Region | 測試店 ShopId |
|--------|-------------|
| TW     | 8           |
| HK     | 2           |
| MY     | 200017      |

---

## 工作流程

### Step 0：確認設定方式

**第一個問題**，詢問使用者：

> 「請問這個功能的開啟／關閉是透過 `ShopStaticSetting` 來設定的嗎？」
> 選項：`是` / `不確定` / `不是`

- 使用者選 **是** → 繼續詢問第二個問題：

  > 「請問是要**新增**這筆設定，還是**修改既有**的設定值？」
  > 選項：`新增（INSERT）` / `修改既有設定值（UPDATE）`

  - 使用者選 **新增（INSERT）** → 繼續 Step 1
  - 使用者選 **修改既有設定值（UPDATE）** → 回覆以下提示後停止：
    ```
    ℹ️  此 skill 僅處理新增（INSERT）ShopStaticSetting 的情境。
        若要修改既有設定值，請手動組 UPDATE 語法，例如：

    USE WebStoreDB

    UPDATE dbo.ShopStaticSetting
    SET ShopStaticSetting_Value       = '新的 Value',
        ShopStaticSetting_UpdatedUser = 'VSTS{編號}',
        ShopStaticSetting_UpdatedDateTime = GETDATE(),
        ShopStaticSetting_UpdatedTimes    = ShopStaticSetting_UpdatedTimes + 1
    WHERE ShopStaticSetting_ShopId    = {ShopId}
      AND ShopStaticSetting_GroupName = '{GroupName}'
      AND ShopStaticSetting_Key       = '{Key}'
      AND ShopStaticSetting_ValidFlag = 1
    ```
- 使用者選 **不確定** → 回覆以下提示後停止：
  ```
  💡 建議先確認設定方式，可透過以下方式查詢：

  USE WebStoreDB
  SELECT * FROM dbo.ShopStaticSetting WITH (NOLOCK)
  WHERE ShopStaticSetting_Key LIKE '%關鍵字%'

  確認是 ShopStaticSetting 後，再重新呼叫此 skill。
  ```
- 使用者選 **不是** → 回覆：
  ```
  ⚠️  此 skill 僅適用於 ShopStaticSetting 的開關設定。
      請使用其他對應的 skill 或手動組語法。
  ```
  然後停止。

---

### Step 1：收集基本查詢資訊

依序使用 ask_user 工具詢問（**每次只問一個**，等使用者回答後再問下一個）：

1. **VSTS 編號** — 純數字或含 VSTS 前綴（例：`605000` 或 `VSTS605000`），統一加 `VSTS` 前綴存為 `{VSTS_ID}`
2. **Region** — 詢問「請問是哪個市場？」，選項：`TW` / `HK` / `MY`，存為 `{REGION}`
3. **目標 ShopId** — 純數字，可多個（以逗號分隔），存為 `{TARGET_SHOP_IDS}`（陣列）
4. **ShopStaticSetting_GroupName** — 例：`SalesOrderSystemInfo`，存為 `{GROUP_NAME}`
5. **ShopStaticSetting_Key** — 例：`MalaysiaInvoice`，存為 `{SETTING_KEY}`

> ⚠️ **尚未詢問 Value 與商店說明，待測試店確認後再收集。**

---

### Step 2：判斷是否需要測試店確認

根據 `{REGION}` 取得對應測試店：

| Region | 測試店 ShopId |
|--------|-------------|
| TW     | 8           |
| HK     | 2           |
| MY     | 200017      |

存為 `{TEST_SHOP_ID}`。

**判斷邏輯：**

- 若 `{TARGET_SHOP_IDS}` 中**包含** `{TEST_SHOP_ID}` → 表示本次就是在設定測試店，**跳過 Step 3，直接進入 Step 3-B**
- 若 `{TARGET_SHOP_IDS}` 中**不包含** `{TEST_SHOP_ID}` → 需先確認測試店，**進入 Step 3**

---

### Step 3：確認測試店設定（非測試店才執行）

#### 3-1：產生測試店確認 SELECT

展示以下查詢，請使用者到 DB 執行並回報結果：

```
🔍 請先確認測試店設定，執行以下 SELECT 並將結果貼回：

USE WebStoreDB

SELECT *
FROM dbo.ShopStaticSetting WITH (NOLOCK)
WHERE ShopStaticSetting_ValidFlag = 1
  AND ShopStaticSetting_ShopId    = {TEST_SHOP_ID}   -- {REGION} 測試店
  AND ShopStaticSetting_GroupName = '{GROUP_NAME}'
  AND ShopStaticSetting_Key       = '{SETTING_KEY}'
```

#### 3-2：判斷使用者回報的結果

**情況 A：有回傳資料（測試店已有設定）**

```
✅ 測試店 ShopId={TEST_SHOP_ID} 已有此設定，確認測試店已就緒。
   繼續產生正式商店 SQL...
```

→ 進入 Step 3-B（收集剩餘資訊後產生 SQL）。

**情況 B：無回傳資料（測試店尚無設定）**

```
⚠️  警告：{REGION} 測試店（ShopId={TEST_SHOP_ID}）尚無此設定！

    規範要求：正式商店開關前，測試店必須先設定並完成測試。
    建議流程：
      1. 先建立測試店 SQL（ShopId={TEST_SHOP_ID}）並合併至 master
      2. 確認測試店功能正常後，再建立正式商店 SQL

    ❓ 是否仍要強制繼續產生正式商店 SQL？
       - 輸入 Y：強制繼續（請確保你已另外追蹤測試店的補建作業）
       - 輸入 N：停止，改為先產生測試店 SQL
```

- 使用者輸入 **N** → 將 `{TARGET_SHOP_IDS}` 替換為 `[{TEST_SHOP_ID}]`，**進入 Step 3-B 產生測試店的 SQL**
- 使用者輸入 **Y** → 顯示強制繼續提示後進入 Step 3-B：
  ```
  ⚡ 強制繼續。提醒：請記得補建測試店設定並在同一或後續 PR 中一併處理。
  ```

---

### Step 3-B：收集剩餘資訊（測試店確認完成或跳過後執行）

依序使用 ask_user 工具詢問：

1. **ShopStaticSetting_Value** — 要寫入的 Value 值（JSON 或純字串），存為 `{SETTING_VALUE}`
2. **ShopStaticSetting_Description** — 作為欄位說明與 SQL 注解（例：`ELEMIS Singapore`），存為 `{SHOP_DESCRIPTION}`；若使用者直接按 Enter，預設帶入 `{REGION} 測試店`

> 若 Step 3-2 情況 B 使用者選 N（改為建測試店），`{SHOP_DESCRIPTION}` 預設帶入 `{REGION} 測試店`，可讓使用者確認或修改。

收集完成後進入 Step 4。

---

### Step 4：預覽 SQL 並請使用者確認

對每個 `{TARGET_SHOP_IDS}` 中的 ShopId，展示完整 SQL 預覽：

```
📋 即將產生的 SQL 預覽（共 {N} 個商店）：

  資料夾：VSTS/{FOLDER_NAME}/
  檔案名：Step01_Insert_WebStoreDB_ShopStaticSetting_{SETTING_KEY}.sql

  [SQL 內容完整顯示，見下方範本]
```

SQL 範本（每個 ShopId 一個 DECLARE 區塊）：

```sql
/*
  {SHOP_DESCRIPTION} 設定 {SETTING_KEY}
  新增 WebStoreDB ShopStaticSetting 資料
  Group: {GROUP_NAME}
  Key:   {SETTING_KEY}
*/
USE WebStoreDB
GO

DECLARE @shopId BIGINT = {SHOP_ID}; -- {SHOP_DESCRIPTION}

-- SELECT（若有查詢到內容，則通知 PR owner，確認是否重複）
SELECT *
FROM dbo.ShopStaticSetting WITH (NOLOCK)
WHERE ShopStaticSetting_ValidFlag = 1
  AND ShopStaticSetting_ShopId    = @shopId
  AND ShopStaticSetting_GroupName = '{GROUP_NAME}'
  AND ShopStaticSetting_Key       = '{SETTING_KEY}';

-- INSERT
INSERT INTO dbo.ShopStaticSetting
(
    ShopStaticSetting_ShopId,
    ShopStaticSetting_GroupName,
    ShopStaticSetting_Key,
    ShopStaticSetting_Value,
    ShopStaticSetting_Description,
    ShopStaticSetting_ValidFlag,
    ShopStaticSetting_CreatedUser,
    ShopStaticSetting_CreatedDateTime,
    ShopStaticSetting_UpdatedDateTime,
    ShopStaticSetting_UpdatedUser,
    ShopStaticSetting_UpdatedTimes
)
VALUES
(
    @shopId,
    '{GROUP_NAME}',
    '{SETTING_KEY}',
    '{SETTING_VALUE}',
    '{SHOP_DESCRIPTION}',
    1,
    '{VSTS_ID}',
    GETDATE(),
    GETDATE(),
    '{VSTS_ID}',
    0
);

-- VERIFY（應回傳 1 筆）
SELECT *
FROM dbo.ShopStaticSetting WITH (NOLOCK)
WHERE ShopStaticSetting_ValidFlag = 1
  AND ShopStaticSetting_ShopId    = @shopId
  AND ShopStaticSetting_GroupName = '{GROUP_NAME}'
  AND ShopStaticSetting_Key       = '{SETTING_KEY}';
```

詢問：「以上資訊正確嗎？確認後將建立資料夾與 SQL 檔案。」

> ⚠️ **使用者確認前不建立任何檔案。**

---

### Step 5：建立資料夾與 SQL 檔案

#### 5-1：自動取得 Repo 根目錄（靜默執行，不詢問使用者）

```shell
git rev-parse --show-toplevel
```

- 將結果存為 `{REPO_ROOT}`（例：`C:\91APP\nineyi.database.operation`）
- 若指令失敗（不在 git repo 中），詢問使用者：
  > 「無法自動偵測 repo 路徑，請手動輸入 repo 根目錄路徑（例：`C:\91APP\nineyi.database.operation`）」
  > 並將輸入值存為 `{REPO_ROOT}`

#### 5-2：建立資料夾與寫入檔案

資料夾命名：`VSTS/{VSTS_ID}_{FOLDER_SUFFIX}/`
其中 `{FOLDER_SUFFIX}` 請詢問使用者（若使用者未提供，預設為 `Insert_WebStoreDB_ShopStaticSetting_{SETTING_KEY}`）。

```powershell
$folderPath = "{REPO_ROOT}\VSTS\{FOLDER_NAME}"
$sqlFile    = "$folderPath\Step01_Insert_WebStoreDB_ShopStaticSetting_{SETTING_KEY}.sql"

New-Item -ItemType Directory -Path $folderPath -Force
```

將替換好的 SQL 內容（多個 ShopId 合併至同一檔案，每個 ShopId 一個區塊，區塊間以 `GO` 分隔）寫入 `$sqlFile`。

完成後顯示：

```
✅ 完成！

  資料夾：VSTS/{FOLDER_NAME}/
  SQL 檔：Step01_Insert_WebStoreDB_ShopStaticSetting_{SETTING_KEY}.sql
  涵蓋商店（{REGION}）：{TARGET_SHOP_IDS}

⚠️  提醒：
  - 執行前請先確認 SELECT 是否已有回傳資料（有則通知 PR owner）
  - 請自行建立 branch、commit、push 並開啟 PR
```

---

## 注意事項

- **測試店優先原則**：正式商店 INSERT 前，對應區域測試店必須已有相同 `GroupName + Key` 設定
- **多 ShopId**：多個 ShopId 寫入同一 SQL 檔，每個獨立區塊，方便逐筆執行與驗證
- **重複設定檢查**：SQL 中的前置 SELECT 用於確認是否已存在相同設定，若有需通知 PR owner
- **Value 格式**：原樣寫入，不做任何轉換；若 Value 含單引號，使用者應自行跳脫（`''`）
- **強制繼續記錄**：若使用者強制跳過測試店確認，SQL 檔開頭注解應加入 `-- ⚡ 測試店確認已略過，請補建` 警示
