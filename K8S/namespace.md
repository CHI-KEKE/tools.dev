

## Namespace 的資源上限

https://91app.slack.com/archives/CJHPX1DGF/p1746165782611889

```plaintext
pods "promotion-web-api-76d9db5667-8wxfr" is forbidden: exceeded quota: default-4w42q, requested: limits.cpu=2250m, used: limits.cpu=7250m, limited: limits.cpu=8:Deployment does not have minimum availability.
```

這段訊息其實同時包含了三個層面的資訊

- 1️⃣ 資源配額（ResourceQuota）超限
- 2️⃣ Pod 建立被拒絕（forbidden）
- 3️⃣ Deployment 無法達到最低可用數量（minimum availability）

| 部分                                                         | 意義                                                                             |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **pods "promotion-web-api-76d9db5667-8wxfr" is forbidden** | 這個 Pod 嘗試被建立時，被 Kubernetes API Server 拒絕。                                      |
| **exceeded quota: default-4w42q**                          | 你所在的 Namespace 有設定一個 ResourceQuota（名字是 `default-4w42q`），Pod 的請求超過了這個 quota 限制。 |
| **requested: limits.cpu=2250m**                            | 新 Pod 嘗試要求 2250m（即 2.25 核心）的 CPU limit。                                        |
| **used: limits.cpu=7250m**                                 | 目前該 Namespace 裡已經使用了 7250m（即 7.25 核心）。                                         |
| **limited: limits.cpu=8**                                  | 這個 Namespace 被限制的上限是 8 核心。                                                     |
| **Deployment does not have minimum availability**          | 因為 Pod 沒建起來，Deployment 無法達到期望的 replica 數（例如希望 3 副本，實際只跑 2）。                    |

<br>
<br>

## 資源調整的觀察

https://91app.slack.com/archives/G04TVB3KW/p1731976146146319

- request 下降
- Node 數量未減少
- Throttled 較常出現
- 有遇到 Limits 沒有正常套用的情形，目前在 rancher 手動調整 limits
- chart 檔 limits 需使用 pipeline v1.3.3-stable