# Domain Catalog

> 集中管理所有 Domain 的「專有名詞 / 關鍵字 Mapping」，方便依關鍵字反查所屬 Domain，也作為跨 Domain 的業務語意總覽。
> 由 `common-b2e-domain-initialize` Agent 在每次建立新 Domain 時自動維護（Step 4）。
>
> **維護原則：**
> - 內容對應各 Domain `00-overview.md` 的「專有名詞 / 關鍵字 Mapping」整合表格
> - 同一 Domain 在 overview 有幾列，Catalog 就同步幾列（共用相同的 `Domain` 與 `文件連結`）
> - 同列的英文關鍵字若有多個，以逗號分隔，請窮舉程式碼中可能對應的所有名詞（含同義詞 / 相近詞）
> - 業務說明欄位用業務語言描述語意；若同列有多個英文關鍵字，請說明彼此差異與適用情境
> - `文件連結`欄位指向該 Domain 的**資料夾**（例：`./domain-Member/`），點擊後可直接開啟該 Domain 的整個文件目錄
> - 與各 Domain 的 `00-overview.md` 內表格同步維護，兩處不可不一致

---

## 使用方式

**依關鍵字反查 Domain：**

1. 在本檔案中搜尋目標關鍵字（例如 `VipMember`）
2. 從同一列的 `Domain` 欄位取得 Domain 名稱
3. 從 `文件連結` 欄位開啟該 Domain 的資料夾，瀏覽 00-overview.md 等完整 SD 文件

**新增 / 更新關鍵字：**

- 新 Domain：執行 `common-b2e-domain-initialize` Agent，會自動追加一列
- 既有 Domain 的關鍵字異動：執行 `common-b2e-code-to-doc-executor` Skill 同步異動，或手動更新本檔與對應 `00-overview.md`

---

## 專有名詞 / 關鍵字 Mapping 索引

| Domain | 中文名 | 英文關鍵字 | 業務說明 | 文件連結 |
|---|---|---|---|---|
| Member | 會員 | `Member`, `VipMember`, `CrmMember` | `Member` 為平台註冊會員、`VipMember` 為付費 VIP 等級會員、`CrmMember` 為 CRM 系統同步過來的會員 | [./domain-Member/](./domain-Member/) |
| _{Domain 名稱}_ | _{中文業務名稱}_ | _`Keyword1`, `Keyword2`_ | _{業務語意定義；多個關鍵字時說明彼此差異}_ | _[./domain-{名稱}/](./domain-{名稱}/)_ |

---

> 最後更新時間：YYYY-MM-DD HH:MM
