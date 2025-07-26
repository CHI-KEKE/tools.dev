# AWS EC2 操作指南

## 目錄
- [Target Group 與 EC2 中 Nginx Proxy 架構](#target-group-與-ec2-中-nginx-proxy-架構)
  - [背景說明](#背景說明)
  - [什麼是 Target Group](#什麼是-target-group)
  - [Target Group 與 Proxy（Nginx）的關係](#target-group-與-proxynginx的關係)
  - [為什麼需要用 Target Group](#為什麼需要用-target-group)
  - [Nginx 在 EC2 裡做什麼](#nginx-在-ec2-裡做什麼)
  - [Proxy Domain 與 Real Domain 的差異](#proxy-domain-與-real-domain-的差異)
  - [實務操作與排錯](#實務操作與排錯)
- [Elastic IP (EIP)](#elastic-ip-eip)
  - [什麼是 Elastic IP](#什麼是-elastic-ip)
  - [為什麼需要 Elastic IP](#為什麼需要-elastic-ip)
  - [什麼是 Associate Elastic IP](#什麼是-associate-elastic-ip)
  - [完整操作流程](#完整操作流程)
  - [完整案例](#完整案例)
  - [注意事項](#注意事項)
- [關於連線 EC2 方法說明](#關於連線-ec2-方法說明)
  - [什麼是 SSH Key Pair](#什麼是-ssh-key-pair)
  - [檔案格式差異](#檔案格式差異)
  - [常見連線方式與情境](#常見連線方式與情境)
  - [總結比較](#總結比較)
- [VPC / IGW](#vpc--igw)
  - [VPC 網路元件說明](#vpc-網路元件說明)
  - [真實情境案例](#真實情境案例)
  - [建立 VPC 的步驟](#建立-vpc-的步驟)
  - [Elastic IP 與 Internet Gateway 的關係](#elastic-ip-與-internet-gateway-的關係)
- [Security Group](#security-group)
  - [Security Group 是什麼](#security-group-是什麼)
  - [主要特性](#主要特性)
  - [範例規則](#範例規則)
  - [入站 vs 出站](#入站-vs-出站)
  - [常見使用情境](#常見使用情境)
  - [安全群組與 NACL 比較](#安全群組與-nacl-比較)
  - [Security Group 的歸屬關係](#security-group-的歸屬關係)

<br><br>

---

## Target Group 與 EC2 中 Nginx Proxy 架構

### 背景說明

在 AWS EC2 → Load Balancing → Target Groups 頁面中，常會看到如 proxy-qa1-hk-91dev-tw-tcp-80 的 Target Group 名稱。

<br>

- 什麼是 Target Group？
- 與 Proxy（例如 Nginx）之間的關係
- 為什麼在 EC2 裡要用 Nginx？它要分流給誰？
- Proxy domain 與 real domain 的關係與實務應用

<br>

### 什麼是 Target Group

在 AWS 中, Target Group 是一組目標伺服器的清單，讓 Load Balancer（ELB / ALB / NLB）知道要把請求導向哪些 EC2。

<br>

🧠 你可以這樣想：

ELB 是店員，負責接收客人（使用者請求）, Target Group 是外送清單，告訴店員要把訂單送到哪裡（哪台 EC2）, EC2 是廚房，實際處理請求

<br>

### Target Group 與 Proxy（Nginx）的關係

在你的畫面中，可能看到這樣的 Target Group 名稱：

proxy-qa1-hk-91dev-tw-tcp-80
proxy-qa1-hk-91dev-tw-tcp-443

<br>

這代表：

- proxy-qa1：代表 QA 環境的代理伺服器服務
- hk：部署區域是香港
- tcp-80 / tcp-443：分別對應 HTTP / HTTPS 服務
<br>

這些 Target Group 是用來把 ELB 的請求導向 EC2 機器，而 EC2 上跑的就是 Nginx 等反向代理伺服器。

<br>

### 為什麼需要用 Target Group

| 功能 | 說明 |
|------|------|
| 分流處理 | 可針對不同 port（HTTP/HTTPS）或服務分開設計 Target Group |
| 健康檢查 | ELB 定期偵測機器健康狀態，只將流量導向健康的 target |
| 動態擴展 | 搭配 Auto Scaling，機器會自動加入/移出 target group |
| 多區域部署 | 可根據地區設計多組 target group，如 HK / MY |

<br>

### Nginx 在 EC2 裡做什麼

即使只有一台 EC2，裡面仍可能跑多個應用程式或容器：

<br>

✅ **實例：同機多服務**

| 應用名稱 | Port |
|---------|------|
| Web 前台 | 3000 |
| API 服務 | 5000 |
| 後台管理 | 8000 |

<br>

🔹 **Nginx 設定**：

```nginx
server {
    listen 80;
    server_name shop.qa1.hk.91dev.tw;

    location / {
        proxy_pass http://localhost:3000;
    }

    location /api/ {
        proxy_pass http://localhost:5000;
    }

    location /admin/ {
        proxy_pass http://localhost:8000;
    }
}
```

Nginx 是 EC2 裡的「接待櫃台」，根據路徑把請求導給正確應用。

<br>

### Proxy Domain 與 Real Domain 的差異

| 類別 | 說明 | 範例 |
|------|------|------|
| Proxy Domain | 對外公開的網址 | shop.qa1.hk.91dev.tw |
| Real Domain | Nginx 內部轉發目標（本地 port、IP 或內部 DNS） | localhost:5000、api.internal.local |

<br>

這種設計可將內部服務隱藏起來、強化安全性與擴展性。

<br>

### 實務操作與排錯

若發現某個服務連不上，例如：

使用者打不開 http://shop2.shop.qa1.hk.91dev.tw/home.html

<br>

你可以依序做以下排查：

1. 在本地 hosts 綁定測試：

```
10.51.107.37 shop2.shop.qa1.hk.91dev.tw
```

2. 嘗試瀏覽器連線看是否成功

3. 進入 AWS Console，檢查對應 Target Group（例如 proxy-qa1-hk-91dev-tw-tcp-80）若顯示 Unhealthy，請通知 Infra team 處理

<br>

Target Group 是 ELB 把流量導向的 EC2 清單

<br>

EC2 上通常會部署 Nginx 做為反向代理

<br>

即使只有一台 EC2，也可能有多個服務（或容器）需要 Nginx 幫忙分流

<br>

Proxy domain 是對外名稱，實際流量會轉發給內部 real domain 或服務

<br>

Nginx 是 AWS 架構中不可或缺的交通指揮官，將負載平衡與實際業務邏輯解耦，提升系統彈性與可維運性

<br><br>

---

## Elastic IP (EIP)

### 什麼是 Elastic IP

在 AWS 裡，Elastic IP 是一種「固定不變的公共 IP 位址」，你可以分配給 EC2 主機使用。

<br>

你可以把它想成：

📬 Elastic IP 就像一個門牌號碼

<br>

AWS 中每次 EC2 重啟都可能換門牌（IP），而 Elastic IP 是你自己保留的門牌，可以永久貼在任一棟 EC2 上。

<br>

### 為什麼需要 Elastic IP

預設情況下，EC2 若沒有固定 IP，重啟之後它的「Public IP」會改變。

<br>

這對以下場景很麻煩：

| 場景 | 問題 |
|------|------|
| 有對外 API、服務 | 用戶 IP 記錄會失效 |
| 設定 DNS 指向 EC2 IP | IP 改變會導致網站無法連線 |
| 防火牆需要允許固定來源 IP | IP 改變會被擋掉 |

<br>

所以你可以申請一個 EIP，然後綁定在你想要的 EC2 上，就可以解決這個問題。

<br>

### 什麼是 Associate Elastic IP

這是將你「保留的 Elastic IP」指定（綁定）到某個 EC2 或 ENI（網路介面）上。

<br>

你可以想像成：

「📮 把你手上的門牌號碼，貼到 EC2 的門口上」

<br>

### 完整操作流程

🎯 **目標**：我有一台 EC2，是後端服務器，我希望它的 IP 不會改變，讓其他前端系統可以安全存取。

<br>

👣 **步驟**：

**1️⃣ 建立 EC2**（你可能早就有了）

假設你已經有一台 EC2，Public IP 是動態的（重開會變）。

<br>

**2️⃣ 分配一個 Elastic IP**

到 EC2 → Elastic IPs → 點「Allocate Elastic IP address」→ 拿到一組 IP（例如：54.219.100.200）

<br>

**3️⃣ Associate Elastic IP**（綁定）

選剛剛分配的 Elastic IP → Action → Associate → 選擇你的 EC2 或其網路介面（通常是 eth0）

<br>

完成後，該 EC2 的對外 IP 就會變成你保留的那組 Elastic IP。

<br>

**4️⃣ 測試與應用**

你可以把 DNS A 記錄（如 api.myservice.com）指向這組 IP

<br>

即使 EC2 重開機，這 IP 不會變

<br>

若要換主機，只要 Unassociate 再重新 Associate 到別台就好

<br>

### 完整案例

**部署可被 DNS 指向的 API Server**

<br>

☁️ **背景**：你有個部署在 EC2 上的 API，前端團隊會打這個 API，你希望它的 IP 永遠不變。

<br>

✅ **操作流程**：

1. 建立 EC2：開一台 Ubuntu + Nginx 的主機
2. 安裝你的 API（用 Node.js、ASP.NET 等）
3. 到 EC2 控制台 → Elastic IP → Allocate → 拿到 54.219.100.200
4. Associate 到你這台 EC2
5. 前端 DNS 做設定：api.company.com → 54.219.100.200

<br>

這樣不管 EC2 重開幾次，IP 都不變，DNS 指向也穩定。

<br>

### 注意事項

| 項目 | 說明 |
|------|------|
| 💰 收費 | 每個帳號前 1 個 EIP 免費（只要有綁主機就不會收費），但若你分配了 EIP 又沒有綁 EC2，就會被收費 |
| ❌ 一台主機只能綁 1 個 Public EIP | 一般情況下一個 ENI 一個 EIP（除非你配置多網卡） |
| 🔁 可以解除綁定再重新綁別台主機 | EIP 可以「轉移」 |
| 🔐 安全考量 | 如果有人掃 IP 掃到這台，請記得設好防火牆規則（SG）和 NACL |

<br>

Elastic IP = 你自己保留的固定公共 IP，Associate Elastic IP = 把這個 IP 貼在某台 EC2 主機上使用。

<br>

就像你買了一個門牌號碼，可以貼在你不同的房子上，不會跟著房子走，而是跟著你走。

<br><br>

---

## 關於連線 EC2 方法說明

### 什麼是 SSH Key Pair

在 AWS EC2 中，你連接實例不會用帳號密碼，而是透過一組「非對稱加密金鑰對」來連線：

<br>

| 類型 | 功能說明 |
|------|---------|
| Private Key（私鑰） | 放在你自己本地電腦，類似鑰匙 |
| Public Key（公鑰） | 放在 EC2 上，類似鎖 |

<br>

這就是你在建立 EC2 時下載的 .pem 檔案 —— 它是私鑰的一種格式。

<br>

### 檔案格式差異

**.pem vs .ppk**

| 格式 | 全名 | 使用場景 | 支援工具 | 產生方式 |
|------|------|---------|---------|---------|
| .pem | Privacy Enhanced Mail | OpenSSH（Linux/macOS、Windows Terminal）預設支援 | ssh 指令 | AWS EC2 建立 Key Pair 時下載 |
| .ppk | PuTTY Private Key | PuTTY 專用（Windows GUI 工具） | PuTTY、WinSCP、Pageant | 使用 PuTTYgen 將 .pem 轉換而來 |

<br>

簡單說：

Linux/macOS/WSL 用 .pem

<br>

純 Windows GUI 環境用 .ppk（PuTTY）

<br>

### 常見連線方式與情境

📘 **情境一：用 Mac/Linux 連 EC2**

你直接用 Terminal：

```bash
ssh -i ~/Downloads/TokyoEC2KeyPair.pem ubuntu@52.193.218.102
```

✅ 不需轉換格式，因為 Mac/Linux 內建支援 .pem。

<br>

📘 **情境二：用 Windows Terminal（內建 OpenSSH）**

```bash
ssh -i "C:\Users\Allen\Downloads\TokyoEC2KeyPair.pem" ubuntu@52.193.218.102
```

✅ 從 Windows 10 開始，PowerShell/Command Prompt 也支援 .pem。

<br>

📘 **情境三：用 PuTTY GUI 連線**

PuTTY 只能讀 .ppk 格式，所以你需要：

<br>

1. 開啟 PuTTYgen
2. 匯入 .pem
3. 點擊「Save private key」存成 .ppk
4. 開啟 PuTTY，設定：
   - Host Name: ubuntu@52.193.218.102
   - Connection → SSH → Auth → 選擇你的 .ppk

<br>

✅ 適合不熟 Terminal、喜歡 GUI 的使用者

<br>

📘 **情境四：用 WinSCP 傳檔案（GUI）**

WinSCP 也只能使用 .ppk，所以情境與 PuTTY 類似：

<br>

1. 用 PuTTYgen 轉換 .pem → .ppk
2. WinSCP 設定使用該 .ppk 即可登入傳檔

<br>

### 總結比較

| 工具/系統 | 支援格式 | 備註 |
|----------|---------|------|
| macOS/Linux | .pem | 直接支援 ssh 指令 |
| Windows Terminal | .pem | Windows 10 以上也支援 |
| PuTTY | .ppk | GUI 工具，需轉換格式 |
| WinSCP | .ppk | 傳檔 GUI 工具，需 .ppk |
| PuTTYgen | 轉換工具 | 可將 .pem 轉為 .ppk |

<br>

**選擇的重點**：

你是誰？→ 熟 CLI 的用 .pem，喜歡 GUI 的用 .ppk

<br>

系統是什麼？→ Windows 上用 .ppk 的工具多一些

<br>

檔案來源是什麼？→ AWS Key Pair 預設給你 .pem

<br><br>

---

## VPC / IGW

### VPC 網路元件說明

VPC（Virtual Private Cloud） 就像是你在雲端世界中的私人資料中心。你可以把它想像成一塊你自己劃定的土地，在這塊土地上你可以蓋房子（EC2）、設置大門（防火牆）、規劃馬路（子網路、路由表），讓進出的人（網路流量）照你設定的規則來走。

<br>

| 元件名稱 | 說明 | 城市比喻 |
|---------|------|---------|
| **VPC** | 整個虛擬網路空間 | 一整座城市 |
| **Subnet（子網路）** | 把 VPC 切成幾個區塊，例如前台/後台區 | 一個區（例如商業區、住宅區） |
| **Route Table** | 流量怎麼走的規則 | 道路指示圖 |
| **Internet Gateway（IGW）** | 讓你的城市連到外部世界（Internet） | 城市的出入口、網際網路大門 |
| **NAT Gateway** | 給內部伺服器對外上網用，但不讓外面主動連進來 | 郵差可以出去送信，但陌生人不能直接進入 |
| **Security Group** | 控制進出每棟建築的規則 | 守衛（類似防火牆） |
| **Network ACL** | 控制整個區（子網）進出交通的規則 | 道路口的警衛 |

<br>

在 AWS 中不是所有資源都預設是安全的。VPC 讓你掌控你的網路邊界、安全性與存取方式。沒有 VPC，你的 EC2 可能就像一個開門的房子，誰都能進來。

<br>

### 真實情境案例

**電商平台的部署架構**

想像你要在 AWS 上架設一個電商網站：

| 需求 | 架構設計 |
|------|---------|
| 用戶可以從網路連到網站 | 建立一個公開子網（Public Subnet）放 EC2 + ALB + Internet Gateway |
| 資料庫要很安全 | 建立一個私有子網（Private Subnet）放 RDS，不開放 Internet 連線 |
| EC2 可以對外更新程式 | 建立 NAT Gateway 讓私有子網內的 EC2 對外連網更新（但外部無法連進） |
| 流量有安全控管 | 設定 Security Group：前台只開 HTTP/HTTPS，資料庫只允許 EC2 的 IP 存取 |

<br>

### 建立 VPC 的步驟

簡化流程：

<br>

1. 建立 VPC（指定 CIDR 範圍，例如 10.0.0.0/16）
2. 建立子網路（Public + Private）
3. 建立並附加 Internet Gateway（給 Public Subnet 使用）
4. 設定 Route Table（讓子網知道流量要走哪裡）
5. 建立 NAT Gateway（給 Private Subnet 對外用）
6. 設定 Security Group 與 ACL
7. 建立 EC2、RDS 等資源並指定子網

<br>

### Elastic IP 與 Internet Gateway 的關係

**有 Elastic IP 的 EC2，一定還需要 Internet Gateway？**

是的。Elastic IP 是靜態的公有 IP 地址，但它要發揮作用，還是必須搭配 Internet Gateway 才能讓外部網路（例如你的電腦）可以存取那台 EC2。

<br>

✅ **正確組合**：

EC2 有 Elastic IP 放在 Public Subnet（子網有 Route Table 指向 Internet Gateway）

<br>

VPC 中有設好 Internet Gateway（並已附加在 VPC 上）

<br>

👉 才能從 Internet 連到這台 EC2！

<br>

🔧 **所以 Elastic IP 是什麼角色？**

它是「你 EC2 對外的門牌號碼」，但這扇門還是要開通（透過 Internet Gateway）。

<br>

🔹 **「子網指向 Internet Gateway」是什麼意思？**

這是指你要在 子網的 Route Table（路由表）裡設定一條規則，告訴它：

「如果有封包要出 Internet，就要走 Internet Gateway。」

<br>

📘 **AWS 裡具體設定方式**：

- 目的地（Destination）：0.0.0.0/0
- 目標（Target）：Internet Gateway（igw-xxxxxxx）

<br>

這條規則意思就是：

所有不是內部 IP 的封包，都轉給 Internet Gateway 去處理。這樣 EC2 才能對外提供服務或上網。

<br>

VPC 是你在 AWS 上蓋的虛擬城市（私有網路），而 IGW（Internet Gateway）是這個城市通往外部世界（Internet）的出入口。

<br><br>

---

## Security Group

### Security Group 是什麼

Security Group 是：

- 作用在 EC2 實例層級的防火牆
- 控制「哪些 IP 可以連進來（入站）」、「你的實例可以連去哪裡（出站）」
- 只適用於 VPC 內的資源（如 EC2、RDS、Lambda、Load Balancer）

<br>

### 主要特性

| 特性 | 說明 |
|------|------|
| 狀態式（Stateful） | 入站連線允許後，對應的出站自動允許，反之亦然 |
| 預設拒絕所有 | 所有入站預設封鎖，所有出站預設允許（可修改） |
| 可重複使用 | 一個 Security Group 可套用多個 EC2 |
| 規則為允許制 | 無法寫拒絕規則（不像 Network ACL），只能允許哪些流量通過 |

<br>

### 範例規則

| 類型 | 協定 | Port 範圍 | 來源 |
|------|------|----------|------|
| 入站 | TCP | 22 | 0.0.0.0/0（允許所有人 SSH） |
| 入站 | TCP | 80 | 0.0.0.0/0（允許 HTTP） |
| 入站 | TCP | 443 | 0.0.0.0/0（允許 HTTPS） |
| 出站 | ALL | ALL | 0.0.0.0/0（預設全開） |

<br>

### 入站 vs 出站

**入站（Inbound）規則**：

控制「誰可以連進來」

<br>

例：允許特定 IP 用 SSH 連你的 EC2（port 22）

<br>

**出站（Outbound）規則**：

控制「實例可以連去哪裡」

<br>

例：讓 EC2 可以連外部網站下載更新

<br>

### 常見使用情境

**Web Server**

開放 HTTP (80)、HTTPS (443)、SSH (22)

<br>

**Database Server**

只允許來自 Web Server 的私網連線（例如 port 3306 for MySQL）

<br>

**內部服務**

使用 Security Group Reference 讓特定群組之間互通

<br>

### 安全群組與 NACL 比較

| 項目 | Security Group | Network ACL |
|------|---------------|-------------|
| 層級 | 實例層級 | 子網層級 |
| 狀態性 | ✅ 狀態式 | ❌ 無狀態 |
| 控制類型 | 只能允許 | 可允許/拒絕 |
| 使用難度 | 較簡單 | 較複雜 |

<br>

### Security Group 的歸屬關係

**Security Group 的歸屬關係**

每一個 Security Group 必須隸屬於一個 VPC

<br>

你建立 SG 時，一定要選擇 VPC。

<br>

不同 VPC 的 SG 無法混用。

<br>

**Security Group 是「套用到資源」的**

例如：EC2、RDS、Lambda (ENI)、ALB 等。

<br>

當你把 SG 綁到 EC2，那台 EC2 才會受到 SG 規則保護。

<br>

**比喻**：

VPC = 一座城市

<br>

Security Group = 特定建築物的大門守衛規定

<br>

EC2 / RDS / ALB = 建築物

<br>

這些守衛規定不是城市共用的，而是「綁在某一棟建築」上。

<br>

**能不能一個 SG 給多台 EC2 用？**

可以！同一個 VPC 裡的多個 EC2 可以共用同一個 Security Group（相當於幾棟大樓用同一組守衛規則）。

<br>

但是：不同 VPC 的資源不能共用同一組 SG。

<br>

**實際範例**

**範例 1：前台伺服器**

- SG 名稱：sg-web
- 綁定：EC2-A (Web)、EC2-B (Web)
- Inbound 規則：開 80/443 給所有人、開 22 給公司固定 IP

<br>

**範例 2：資料庫伺服器**

- SG 名稱：sg-db
- 綁定：RDS-DB
- 規則：只允許 sg-web（前台的 SG）存取 3306（MySQL）

這樣外面的人就無法直接連到資料庫。

<br>

**關係圖**：

```
[VPC]
   │
   ├── Security Group sg-web
   │       │
   │       ├── EC2-A (Web)
   │       └── EC2-B (Web)
   │
   └── Security Group sg-db
           │
           └── RDS-DB
```