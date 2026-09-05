# 常用技術術語翻譯對照表

此文件提供程式碼審查規則文件中常用技術術語的中英文對照，確保翻譯一致性。

## A-E

| English | 中文 | 說明 |
|---------|------|------|
| Access | 存取 | |
| Account | 帳號 | |
| Additional Recommendations | 額外建議 | |
| Anti-pattern | 反模式 | |
| API | API | 保持英文 |
| Architecture | 架構 | |
| Authentication | 驗證 / 身份驗證 | |
| Authorization | 授權 | |
| Best Practice | 最佳實踐 | |
| Bug | 錯誤 / Bug | 可保持英文 |
| Code Review | 程式碼審查 / Code Review | |
| Compliant | 合規 / 符合規範 | |
| Configuration | 配置 / 設定 | |
| Cross-store | 跨店 | |
| Data Integrity | 資料完整性 / 數據完整性 | |
| Data Leakage | 資料外洩 / 數據洩漏 | |
| Deprecated | 已棄用 | |
| Documentation | 文件 | |
| Exception | 例外 / 例外狀況 | |

## F-M

| English | 中文 | 說明 |
|---------|------|------|
| Framework | 框架 | |
| Implementation | 實作 / 實現 | |
| Interface | 介面 | |
| Issue | 問題 | |
| Linter | Linter / 程式碼檢查工具 | |
| Maintainability | 可維護性 | |
| Method | 方法 | |
| Middleware | 中介軟體 / Middleware | |

## N-S

| English | 中文 | 說明 |
|---------|------|------|
| Namespace | 命名空間 | |
| Noncompliant | 不合規 / 不符合規範 | |
| Pattern | 模式 | |
| Performance | 效能 / 性能 | |
| Property | 屬性 | |
| Query | 查詢 | |
| Refactoring | 重構 | |
| Repository | Repository / 儲存庫 | 通常保持英文 |
| Resource | 資源 | |
| Security | 安全性 | |
| Severity | 嚴重性 | |
| Solution | 解決方案 | |
| Static Analysis | 靜態分析 / 靜態程式碼分析 | |
| Status | 狀態 | |

## T-Z

| English | 中文 | 說明 |
|---------|------|------|
| Template | 範本 / 模板 | |
| Testing | 測試 | |
| Time Zone | 時區 | |
| Transaction | 交易 | |
| Type | 型別 / 類型 | |
| Unauthorized | 未授權 | |
| Validation | 驗證 | |
| Variable | 變數 | |
| Vulnerability | 漏洞 / 安全漏洞 | |
| Workflow | 工作流程 | |

## 專業術語保持英文

以下術語建議在中文文件中保持英文：

- **資料類型**: `DateTime`, `DateTimeOffset`, `string`, `int`, `bool` 等
- **關鍵字**: `public`, `private`, `class`, `interface`, `async`, `await` 等
- **框架名稱**: `.NET`, `Entity Framework`, `LINQ` 等
- **設計模式**: `Repository Pattern`, `Factory Pattern` 等
- **工具名稱**: `SonarQube`, `ReSharper`, `StyleCop` 等
- **技術縮寫**: `API`, `CRUD`, `DTO`, `ORM`, `SQL` 等

## Severity 級別

| English | 中文 | 使用建議 |
|---------|------|---------|
| BLOCKER | BLOCKER | 保持英文 |
| CRITICAL | CRITICAL | 保持英文 |
| MAJOR | MAJOR | 保持英文 |
| MINOR | MINOR | 保持英文 |
| INFO | INFO | 保持英文 |

## Status 狀態

| English | 中文 | 使用建議 |
|---------|------|---------|
| READY | READY | 保持英文 |
| BETA | BETA | 保持英文 |
| DEPRECATED | DEPRECATED / 已棄用 | 可翻譯可保留 |

## 章節標題翻譯

| English | 中文 |
|---------|------|
| Why is this an issue? | 為什麼這是個問題? |
| Noncompliant Code Example | 不合規的程式碼範例 / 錯誤範例(不符合規範) |
| Compliant Solution | 合規的解決方案 / 正確範例(符合規範) |
| Issues | 問題 |
| Solution | 解決方案 |
| Additional Recommendations | 額外建議 |
| Resources | 資源 |
| Exceptions | 例外情況 |
| Tips and Best Practices | 提示與最佳實踐 |

## 翻譯原則

1. **一致性優先**: 同一文件中相同術語使用相同翻譯
2. **保持專業性**: 使用業界標準翻譯
3. **避免過度翻譯**: 廣為人知的英文術語可保持原文
4. **上下文考量**: 根據語境選擇最合適的翻譯
5. **程式碼保持英文**: 程式碼範例中的識別符號、關鍵字等保持英文

## 特殊情況處理

### 複合詞
- `code review` → 程式碼審查 (不要分開翻譯)
- `data integrity` → 資料完整性 (整體翻譯)

### 動詞 vs 名詞
- Validate (動詞) → 驗證
- Validation (名詞) → 驗證

### 台灣 vs 中國用語
優先使用台灣慣用語：
- 資料 (台) vs 數據 (中)
- 軟體 (台) vs 軟件 (中)
- 網路 (台) vs 網絡 (中)
