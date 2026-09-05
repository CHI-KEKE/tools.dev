# Cross-Cutting Concerns — 橫切關注點分析

---

## 分析範疇

聚焦對此功能**最相關**的面向，避免樣板化分析。

---

## Security（安全性）

分析重點：
- 未授權存取風險（端點是否有 `[Authorize]` 保護）
- 資料驗證層次（API 層 + Service 層防禦深度）
- 敏感資料處理（加密、遮罩、Log 過濾）
- SQL Injection 防範（使用 ORM / Parameterized Query）

輸出格式：
```markdown
##### 🔐 Security
- **風險：** {描述具體風險}
- **緩解措施：**
  - {措施 1}
  - {措施 2}
```

---

## Performance（效能）

分析要點：
- N+1 Query 風險（關聯查詢是否有 eager loading）
- 索引覆蓋（WHERE / JOIN / ORDER BY 欄位有無索引）
- 快取機會（高頻讀取、低異動頻率的資料）
- 大量資料分頁（LIST API 是否有 paging）

輸出格式：
```markdown
##### ⚡ Performance
- **潛在瓶頸：** {描述具體瓶頸}
- **優化策略：**
  - {策略 1（例：在 X 欄位加 index）}
  - {策略 2（例：快取 TTL = 5 分鐘）}
```

---

## Maintainability（可維護性）

分析要點：
- 分層清晰度（API / Service / Repository 職責邊界）
- 單元測試覆蓋目標（目標百分比 + 核心關鍵路徑）
- 商業邏輯文件化（複雜驗證規則是否有說明）
- 相依注入（是否都透過 DI，方便 Mock 測試）

輸出格式：
```markdown
##### 🛠️ Maintainability
- **方法：**
  - {措施 1（例：清晰分層架構）}
  - {措施 2（例：Service 層單元測試目標 80%+）}
```

---

## 其他關注點（條件性，視功能範疇決定是否分析）

### Scalability（擴展性）
僅當 WI 有提及高流量、水平擴展需求時分析。

### Observability（可觀測性）
僅當 WI 有提及監控、APM、告警需求時分析。

### Error Handling（錯誤處理）
僅當流程有複雜的跨服務呼叫、非同步流程或重試機制時分析。

---

## 精簡原則

- 僅分析**對此功能實作有直接影響**的面向
- 不需套用全部分類，寫出「本功能不涉及，略過」反而更清晰
- 每個面向的建議應具體到可以直接寫入 Task 的描述中
