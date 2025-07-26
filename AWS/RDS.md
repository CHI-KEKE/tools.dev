# AWS RDS 操作指南

## 目錄
- [什麼是 RDS](#什麼是-rds)
- [為什麼需要 RDS](#為什麼需要-rds)
- [RDS 支援哪些資料庫](#rds-支援哪些資料庫)
- [核心概念](#核心概念)
- [實際案例](#實際案例)
  - [案例一：電商系統的交易資料庫](#案例一電商系統的交易資料庫)
  - [案例二：新創公司 MVP 開發](#案例二新創公司-mvp-開發)
- [架構圖](#架構圖)
- [什麼時候不要用 RDS](#什麼時候不要用-rds)

<br><br>

---

## 什麼是 RDS

RDS 的全名是 Relational Database Service，由 AWS 提供的一項雲端託管關聯式資料庫服務。

<br>

**關鍵詞**：

Relational：關聯式，表示資料表之間有關聯（透過 PK/FK）

<br>

Database：資料庫，儲存資料的地方

<br>

Service：服務，AWS 幫你管理，而不是你自己架伺服器

<br>

**換句話說**：

RDS 就是 AWS 幫你「代管一台關聯式資料庫伺服器」，你只需要專注在使用資料，而不用自己維護伺服器的安裝、備份、修補和擴展。

<br><br>

---

## 為什麼需要 RDS

在沒有 RDS 之前，你要自己：

- 租一台 EC2 → 安裝 MySQL / PostgreSQL
- 設定網路、防火牆
- 安排備份排程
- 監控 CPU、記憶體，自己升級版本或擴容
- 處理資料異地備援

<br>

RDS 出現後，AWS 幫你包辦：

- 自動備份
- 自動 failover（高可用 Multi-AZ）
- 簡單的升級（點幾下就可以換版本）
- 監控與自動擴容
- 免維護硬體

<br>

本質上：RDS 把「管理資料庫伺服器」這件事變成一種雲端服務。

<br><br>

---

## RDS 支援哪些資料庫

RDS 不是一個單一資料庫，它是一個「平台」，支援多種常見的 DB 引擎：

- MySQL
- PostgreSQL
- MariaDB
- Oracle
- SQL Server
- Amazon Aurora（AWS 自家相容 MySQL/Postgres 的雲原生 DB）

<br><br>

---

## 核心概念

**RDS 做了什麼？（更本質）**

<br>

從系統層次看，RDS 做的事可以分三層：

<br>

**(1) 基礎設施（Infrastructure）**

自動建立 VM（虛擬機器）、磁碟、網路

<br>

你不用管機器在那裡

<br>

**(2) 資料庫管理（DB Administration）**

幫你：

- 自動備份（Point-in-Time Recovery）
- 自動套用安全更新（patch）
- 提供監控（CloudWatch metrics）
- 快速建立副本（Read Replica）

<br>

**(3) 高可用與擴展**

Multi-AZ 部署：一個主節點、一個備援節點，主機壞掉自動切換

<br>

讀寫分離：讀取壓力可以丟給 Read Replica

<br>

這些功能的目標是：讓工程師專心寫應用程式，不要把時間浪費在維運資料庫上。

<br><br>

---

## 實際案例

### 案例一：電商系統的交易資料庫

**情境**：

你有一個電商平台，訂單資料、會員資料、付款紀錄都放在 MySQL。

<br>

流量逐漸增大，擔心資料庫掛掉。

<br>

**如果你自己架**：

- 要每天備份
- 處理高可用（自己架主從）
- 忙著修 VM 或升級資料庫版本

<br>

**使用 RDS**：

- 建立 RDS MySQL（10 分鐘）
- 選擇 Multi-AZ → AWS 自動幫你在另一個 AZ 建立同步備援
- 設定每日自動快照
- 需要報表的讀取量大時，可以直接加 Read Replica

<br>

**好處**：你只專注於 SQL schema 與業務邏輯，所有基礎維運 AWS 包辦。

<br>

### 案例二：新創公司 MVP 開發

**情境**：

只有一個工程師，要快速上線一個社群 app。

<br>

沒有人力養一個 DBA 團隊。

<br>

**RDS 做法**：

- 開一個 Postgres RDS（Single-AZ 就好）
- 用 SQLAlchemy / EF Core 直接連線
- 自動備份避免資料遺失
- 未來產品成功後可以隨時升級 RDS 規格（CPU/記憶體）或開 Multi-AZ

<br>

這樣工程師幾乎不需要碰伺服器運維。

<br><br>

---

## 架構圖

**以電商為例**：

```
User
  ↓
Load Balancer → EC2 / ECS (後端 API)
                      ↓
                   RDS (MySQL)
                      |
                 Multi-AZ (備援)
                      |
              自動備份 / Read Replica
```

RDS 像一個雲端的資料庫黑盒子，API/服務直接連接它，不用管裡面伺服器的細節。

<br><br>

---

## 什麼時候不要用 RDS

- 需要自己改 DB 引擎核心設定（RDS 有些參數限制）
- 成本預算非常有限（自己架 VM 可能便宜，但風險高）
- 想要 NoSQL 資料庫 → 那就考慮 DynamoDB 而不是 RDS

<br>

RDS 是 AWS 幫你自動化資料庫維運的服務，讓開發者專注於資料與程式，不必煩惱伺服器、備份、高可用與擴展。