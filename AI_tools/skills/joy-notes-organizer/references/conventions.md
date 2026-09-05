# Joy Notes Organizer — 慣例與邊界情況

## 資料夾與命名慣例

| 項目 | 規則 |
|------|------|
| 根路徑 | `C:\Users\Allen Lin\Desktop\joy_2\joy_\` |
| V2 命名 | 原始名稱 + `V2`（BatchUpload → BatchUploadV2） |
| 中文檔名 | 允許，以 Allen 確認的為準（不強制英文） |
| images 子資料夾 | 固定放在 V2 的 `images/` 目錄 |

## 圖片命名範例

| 原始名稱 | 建議改名 |
|---------|---------|
| `image.png` | `batchcrmorder-異常原因.png` |
| `image-1.png` | `sdk-2.png` |

命名邏輯：反映圖片主題，不用序號 image-1/image-2 這種無意義名稱。

## code block 替換規則

PowerShell 替換邏輯（追蹤 $inBlock 狀態）：
- 行符合 `` ^```(\S+) `` → 有語言標記的開頭，設 inBlock=true，**不動**
- 行完全等於 ` ``` ` 且 inBlock=false → 裸露開頭，改成 ` ```bash `，設 inBlock=true
- 行完全等於 ` ``` ` 且 inBlock=true → 關閉行，設 inBlock=false，**不動**

## 提案結構的常見分類方式

以下是過去整理過的分類模式，可作為提案參考：

- `schema/` — 資料表結構、狀態機、Enum 定義
- `types/` — 各種業務類型的個別說明
- `cases/` — 案例記錄（bug、ticket、PR）
- `guides/` — SOP、操作步驟
- `reference/` — SQL 查詢、API、路徑、工具說明

## 比對時的注意清單

- [ ] 每個原始 .md 的每個 `##` 章節都有對應到 V2
- [ ] 所有 code block 中的變數名沒有被簡化
- [ ] 圖片有被複製且路徑已更新
- [ ] 原始檔案中的 PR 連結、案例連結有保留
- [ ] 多個原始檔案有重複內容 → V2 至少保留一份

## 歷史整理紀錄

| 資料夾 | 狀態 | 備註 |
|--------|------|------|
| BatchUpload → BatchUploadV2 | ✅ 已完成刪除 | 14 個 .md，5 張圖片 |
| Config → ConfigV2 | ✅ 已完成刪除 | 5 個 .md，2 張圖片 |
