


直接整包丟給 Dify Bot 可能會遇到 Token 長度限制，或者導致 AI 遺漏細節


## 目前的設計中，是打算「一次性」將整個 PR 的 Diff 送給單一 Bot 處理，還是會先在後端將 Diff 拆解成多個「檔案級別（File-level）」或「區塊級別（Hunk-level）」的任務，分批調用 API 並彙整結果？



## Gitlab


從 GitLab 回傳的 MR diff 裡拿到所有變更檔案（gitlabDiffResponse.Changes）

```json
{
  "web_url": "https://gitlab.com/org/repo/-/merge_requests/123",
  "changes": [
    {
      "old_path": "src/Backend/Orders/OrderService.cs",
      "new_path": "src/Backend/Orders/OrderService.cs",
      "a_mode": "100644",
      "b_mode": "100644",
      "new_file": false,
      "renamed_file": false,
      "deleted_file": false,
      "diff": "@@ -12,6 +12,10 @@ public class OrderService\n+ // TODO: add validation\n"
    },
    {
      "old_path": "src/Frontend/components/Checkout.tsx",
      "new_path": "src/Frontend/components/Checkout.tsx",
      "a_mode": "100644",
      "b_mode": "100644",
      "new_file": false,
      "renamed_file": false,
      "deleted_file": false,
      "diff": "@@ -55,6 +55,8 @@ export const Checkout = () => {\n+ console.log('checkout loaded');\n"
    },
    {
      "old_path": "package.json",
      "new_path": "package.json",
      "a_mode": "100644",
      "b_mode": "100644",
      "new_file": false,
      "renamed_file": false,
      "deleted_file": false,
      "diff": "@@ -10,6 +10,7 @@\n+ \"dayjs\": \"^1.11.10\"\n"
    },
    {
      "old_path": "scripts/check_quality.py",
      "new_path": "scripts/check_quality.py",
      "a_mode": "100644",
      "b_mode": "100644",
      "new_file": false,
      "renamed_file": false,
      "deleted_file": false,
      "diff": "+print('quality check')\n"
    },
    {
      "old_path": "db/migrations/20260209_add_index.sql",
      "new_path": "db/migrations/20260209_add_index.sql",
      "a_mode": "100644",
      "b_mode": "100644",
      "new_file": false,
      "renamed_file": false,
      "deleted_file": false,
      "diff": "+CREATE INDEX CONCURRENTLY idx_x ON t(x);\n"
    }
  ]
}
```

依照「檔名/副檔名」把每個變更檔案分到不同的 AIAssistType 分類桶
逐檔跑 foreach



#### 檔案 1：src/Backend/Orders/OrderService.cs

endsWith(".cs") ✅

加到：
AIAssistType.Backend
AIAssistType.CustomRuleBackend（因為 Item2 有值）

#### 檔案 2：src/Frontend/components/Checkout.tsx

endsWith(".tsx") ✅

加到：

AIAssistType.Frontend
AIAssistType.CustomRuleFrontend

#### 檔案 3：package.json

endsWith("package.json") ✅（注意：這不是副檔名，是檔名直接比對）

加到：

AIAssistType.Frontend
AIAssistType.CustomRuleFrontend


```bash
.cs → (Backend, CustomRuleBackend) ✅會進兩桶
.tsx / .ts / .d.ts / .html / .cshtml / package.json → (Frontend, CustomRuleFrontend) ✅會進兩桶
.py → (Quality, CustomRuleQuality) ✅會進兩桶
.sql → (Postgresql, null) ✅只進一桶
```




最後回傳：Dictionary<AIAssistType, List<Change>>
讓後面可以「針對不同分類」跑不同 AI assist / rule




## baseai


diffContent => 依據 diff 拆出多個 diffSection => 經歷一番篩選 => 針對每一個 diff item 進行 AI Code Review