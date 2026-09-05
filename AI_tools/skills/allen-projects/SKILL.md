---
name: allen-projects
description: Allen Lin 的所有開發專案導覽。當 Allen 提到任何專案名稱、關鍵字（如 codereview、livebuy、shopping、cart、promotion、coupon、payment、linter、erpv2、hexo、joy、tools.dev 等），或說「打開某某專案」、「分析某某專案」、「幫我看某某專案」時，使用此 skill 查找對應路徑並執行對應操作。涵蓋 91APP 公司專案（AI CodeReview、LiveBuy、購物車、Promotion、Coupon、Payment、DB、ERP、Linter、Webstore、Config、SMS、SCM、Notification、Salepage、Commerce Worker 等）以及 Allen 個人專案（電商筆記 joy、工具筆記 tools.dev、技術部落格 Hexo 系列）。
---

# Allen's Project Navigator

## 專案清單

所有專案的完整關鍵字對照表請參閱 `references/projects.md`。

## 標準工作流程

### Step 1 — 識別專案

當 Allen 提到任何關鍵字時，查詢 `references/projects.md` 找到對應的專案名稱與路徑。

若關鍵字模糊（比如「promotion」可能對應多個子專案），**列出所有候選專案**請 Allen 選擇。

### Step 2 — 確認路徑

找到對應專案後，先向 Allen 確認：

> 「你說的是 **{專案名稱}**，路徑在 `{路徑}` 嗎？」

等待 Allen 確認是（yes / 是 / 對）或否。

- 若否：請 Allen 提供更多描述，重新比對。
- 若是：進入 Step 3。

### Step 3 — 詢問操作

確認路徑後，詢問 Allen 要執行什麼操作：

> 「好的！你想要對這個專案做什麼？」

提供常見操作選項：

1. **用 VSCode 打開** → 執行 `code "<路徑>"`
2. **分析專案結構** → 使用 view/glob/grep 工具瀏覽目錄與關鍵檔案
3. **查看 Git 狀態** → 執行 `git -C "<路徑>" status`
4. **查看最近 Git 提交** → 執行 `git -C "<路徑>" log --oneline -10`
5. **用檔案總管開啟** → 執行 `explorer "<路徑>"`
6. **查看目錄結構** → 執行 `Get-ChildItem "<路徑>" -Depth 2`
7. **其他自訂操作** → 依 Allen 的指令執行

### Hexo 部落格專屬操作（技術部落格 / 英文部落格 / 生活體悟）

| 操作 | 指令 |
|------|------|
| **hd（一鍵部署）** | `. $PROFILE; Set-Location "<路徑>"; hd`（clean → generate → deploy） |
| **本地預覽** | `. $PROFILE; Set-Location "<路徑>"; hexo server` |
| **只產生靜態檔** | `. $PROFILE; Set-Location "<路徑>"; hexo generate` |
| **清除快取** | `. $PROFILE; Set-Location "<路徑>"; hexo clean` |

> `hd` 是 Allen 在 PowerShell Profile 定義的自訂函式，需先載入 `$PROFILE` 才能呼叫。

### Step 4 — 執行操作

依 Allen 的選擇執行對應指令，並回報結果。

---

## 快速參考：主要類別

| 類別 | 代表關鍵字 |
|------|-----------|
| AI CodeReview | codereview, rulebase |
| LiveBuy 直播 | livebuy, livebuy-cron, livebuy-worker |
| 購物車 | shopping, cart |
| Promotion 促銷 | promotion, promo-engine, promo-worker |
| Coupon 優惠券 | coupon, coupon-backend |
| Payment 金流 | payment, paymentmiddleware |
| DB 資料庫 | db-csp, db-operation |
| ERP | erp, erpv2 |
| 個人專案 | joy, tools.dev, hexo, hexo-en, hexo-journal |

> 完整清單（含所有關鍵字）：`references/projects.md`
