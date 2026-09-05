
## 14. 🏷️ TAG_ID 標籤管理

TAG_ID 是一個用來標記 Docker 映像（image）的『版本標籤』，通常用來唯一識別一個 build 出來的版本。

<br>

📦 每次包裝一個產品（映像檔），你都貼上一張獨一無二的標籤：這是什麼版本、什麼時候做的、出自哪個分支和 commit。

<br>

### TAG_ID 組成範例

```bash
TAG_ID=$(echo $CI_BUILD_REF_NAME | cut -d'/' -f 2)_\
$(cat package.json | jq -r '.version')_\
$(TZ=Asia/Taipei date '+%y%m%d%H%M')_\
$(echo $CI_BUILD_REF | cut -c 1-7)
```

<br>

**生成結果**：`feature-login_1.2.3_2507201012_ab12cd3`

<br>

### TAG_ID 各部分說明

| 部分 | 說明 |
|------|------|
| feature-login | 分支名稱（例如 feature/login，取 / 後面） |
| 1.2.3 | 專案版本（從 package.json 讀出 .version 欄位） |
| 2507201012 | 建構時間：2025年07月20日 10:12（Asia/Taipei 時區） |
| ab12cd3 | Git commit 的前 7 碼，用來追蹤是誰提交的 |

<br>

### ⚠️ 如果不使用 TAG_ID，會有什麼問題？

很多人習慣直接用：

```bash
docker tag my-app:latest
```

<br>

但這會造成：

- ⛔ 看不出來這是哪次 build 的
- ⛔ 不小心覆蓋掉別人的版本
- ⛔ 難以追蹤 bug 來源或復原版本

<br>




### 案例 5：Deprecated Build CI 參數

**錯誤訊息**：
```
ERROR: Job failed: failed to pull image "docker-proxy.build.91app.io/alpine/git:v2.34.2" with specified policies [always]: Error response from daemon: Head "https://docker-proxy.build.91app.io/v2/alpine/git/manifests/v2.34.2": no basic auth credentials (manager.go:237:0s)
```

<br>

**解決方法**：

修正 Deprecated Build CI 參數

<br>

**範例**：

❌ **錯誤寫法**：
```bash
VER_SUFFIX=$(if [ "$(echo $CI_BUILD_REF_NAME | cut -d'/' -f 2)" = "master" ]; then echo ""; else echo "-dev"; fi)
```

<br>

✅ **正確寫法**：
```bash
VER_SUFFIX=$(if [ "$(echo $CI_COMMIT_REF_NAME | cut -d'/' -f 2)" = "master" ]; then echo ""; else echo "-dev"; fi)
```

<br>

**參考資料**：https://gitlab.com/gitlab-org/gitlab/-/issues/352957




## 19. 🔒 Protected GroupVariable

### 問題描述

groupVariable 被掛上 protected，打 tag 也綁上 protected，可能造成無法正常取得 KUBE CONFIG 導致佈署失敗。

<br>

### 影響範圍

當 GitLab 中的 Group Variables 被設定為 protected 時，會限制只有 protected branches 和 protected tags 才能存取這些變數。

<br>

**可能的問題情況**：

| 情況 | 問題 | 結果 |
|------|------|------|
| 非 protected branch | 無法存取 KUBE_CONFIG | Pipeline 佈署失敗 |
| 非 protected tag | 無法取得部署權限變數 | 權限不足錯誤 |
| CI/CD Pipeline | 取不到必要的環境設定 | 建置或部署中斷 |

<br>

### 解決方案

**步驟 1：檢查 Variable 設定**

確認 Group Variables 中的 protected 設定：
- KUBE_CONFIG 相關變數
- 部署權限相關變數
- 環境設定變數

<br>

**步驟 2：調整 Branch/Tag 保護設定**

根據需求調整以下設定：
- 將必要的 branch 設為 protected
- 或者取消不必要的 variable protected 限制

<br>

**步驟 3：權限對齊**

確保：
- Pipeline 執行的 branch/tag 狀態
- Variable 的 protected 設定
- 兩者權限等級一致



## 20. 👤 CD_User 權限管理

### 概念說明

每個團隊服務會有專用的 CD_User，用於處理持續部署（Continuous Deployment）的權限管理。

<br>

### CD_User 功能架構

**權限配置流程**：

1. **建立專用 CD_User**
   - 每個團隊服務擁有獨立的 CD_User
   - 遵循最小權限原則設計

<br>

2. **K8s 權限授予**
   - 給予 CD_User 必要的 Kubernetes 權限
   - 允許執行 K8s Yaml 的 Apply 操作

<br>

3. **Token 提供**
   - 提供 CD_User 的 Token 給團隊
   - 團隊將 Token 設定在 GitLab 中使用

<br>

### Token 特性

**重要特性**：
- Token **理論上應該不會過期**
- 提供長期穩定的部署權限
- 減少因 Token 過期導致的部署中斷

<br>

![alt text](./image-1.png)

<br>

### 使用流程

| 步驟 | 操作 | 負責方 |
|------|------|--------|
| 1 | 建立 CD_User | Infrastructure 團隊 |
| 2 | 配置 K8s 權限 | Infrastructure 團隊 |
| 3 | 生成 Token | Infrastructure 團隊 |
| 4 | 提供 Token | Infrastructure 團隊 |
| 5 | 設定 GitLab Variables | 開發團隊 |
| 6 | 配置 CI/CD Pipeline | 開發團隊 |

<br>

### 安全考量

**權限隔離**：
- 每個團隊擁有獨立的 CD_User
- 避免權限交叉污染
- 便於權限追蹤和管理

<br>

**Token 管理**：
- 定期檢查 Token 有效性
- 必要時進行 Token 輪換
- 監控 Token 使用狀況

<br>

### 故障排除

**常見問題**：

| 問題 | 可能原因 | 解決方案 |
|------|----------|----------|
| 部署權限不足 | CD_User 權限配置錯誤 | 檢查 K8s RBAC 設定 |
| Token 無效 | Token 過期或被撤銷 | 重新申請 Token |
| Pipeline 失敗 | GitLab 中 Token 設定錯誤 | 確認 Variable 設定正確 |

<br>


$ if [[ -n ${IS_DRY_RUN} ]] && [[ ${IS_DRY_RUN} == "true" ]]; then # collapsed multi-line command                                
Error: query: failed to query with labels: secrets is forbidden: User "u-uhmbmljwy5" cannot list resource "secrets" in API group "" in the namespace "qa-regular-purchase-service"                                                                                
Cleaning up project directory and file based variables                                                                           
00:00                                                                                                                            
ERROR: Job failed: exit code 1                                                                                                   

● 這是 deploy 階段，不是 build 問題（build 已過了）。錯誤是 K8s RBAC 權限問題：

secrets is forbidden: User "u-uhmbmljwy5" cannot list resource "secrets"
in namespace "qa-regular-purchase-service"

原因： CI 的 service account u-uhmbmljwy5 在 namespace qa-regular-purchase-service 沒有操作 secrets 的權限。

這是新 namespace，需要平台團隊開權限。 通常要：

1. 在 K8s 建立 namespace qa-regular-purchase-service
2. 將 CI service account 加入該 namespace 的 RBAC（ClusterRole binding 或 RoleBinding）



## 解法


- 要請 infra 設定



ㄋ


## 18. ❌ Pipeline 錯誤處理紀錄

### 案例 1：docker auth config / am user / am password 相關權限錯誤

**解決步驟**：

<br>

1. 確認 protected branch 是否已設定，這樣才會去抓 auth config
![alt text](./Img/image-6.png)
<br>

2. 確認 variables 是否有正確設定相關權限參數

<br>

3. 向 [@zhongkuo](https://91app.slack.com/team/U05KFQBPD8E), [@kylechang](https://91app.slack.com/team/U07UPKU0GN6) 確認 ciuser 會 variables 是否正確設定

加 release/* Branch 當 Protected Branch



