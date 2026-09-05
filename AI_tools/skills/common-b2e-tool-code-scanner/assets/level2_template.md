# 📂 {模組名稱} 盤點

> **一句話摘要**：{這個模組解決什麼業務問題，20 字以內}

## 模組概述
- **職責**：{詳細描述，2-3 句話說明業務價值和負責範圍}
- **對外介面**：{列出主要 public interface/class 名稱，例如 `IOrderService`、`OrderController`}

## 內部結構

### 目錄結構摘要
```
{ModuleName}/
├── Controllers/     # API 端點（{N} 個 Controller）
├── Services/        # 業務邏輯層（{N} 個 Service）
├── Repositories/    # 資料存取層（{N} 個 Repository）
├── Models/          # 資料模型
│   ├── Requests/    # API 請求 DTO（{N} 個）
│   ├── Responses/   # API 回應 DTO（{N} 個）
│   └── Entities/    # DB Entity（{N} 個）
├── Validators/      # 輸入驗證（{N} 個）
└── Helpers/         # 工具類（{N} 個）
```
*(根據實際結構調整，刪除不存在的目錄)*

### 核心類別清單
| 類別名稱 | 職責 | 重要度 | 行數 |
|---|---|---|---|
| `{ClassName}.cs` | {職責描述} | 🔴 高 | {N} |
| `{ClassName}.cs` | {職責描述} | 🟡 中 | {N} |
| `{ClassName}.cs` | {職責描述} | 🟢 低 | {N} |

*若有大量 DTO/Entity 類別，可彙整：「其餘 N 個 🟢 低重要度 DTO/Entity 類別（略）」*

## 相依關係

### 依賴（此模組用了誰）
| 依賴對象 | 類型 | 用途 |
|---|---|---|
| `{ProjectName}` | 內部模組 | {為什麼用它} |
| `{PackageName}` | NuGet 套件 | {為什麼用它} |

*若無外部依賴，填：「此模組無對外依賴。」*

### 被依賴（誰用了此模組）
| 來源模組 | 引用方式 | 備註 |
|---|---|---|
| `{ProjectName}` | ProjectReference | {備註} |

*若無被引用，填：「此模組為頂層消費者，未被 solution 內其他模組引用。」*

---
*盤點時間：{YYYY-MM-DD HH:MM}*
