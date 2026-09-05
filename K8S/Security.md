## 11. 🔐 IRSA 服務帳戶角色關聯

IRSA 是讓 Kubernetes 裡的 Pod 可以「直接拿到 AWS IAM 權限」的一種安全做法。

<br>

而且這個權限是獨立的、不用再跟其他 Pod 共用，幫助你達成「最小權限原則（Least Privilege）」。

<br>

### 在 EKS 沒有 IRSA 之前

如果你想讓 Pod 存取 AWS 資源（例如 S3、DynamoDB、SQS），你會這樣做：

<br>

1. 把 IAM Role 綁在 EC2 Node（也就是 Kubernetes 的 Worker Node）上
2. 這樣上面跑的所有 Pod 都會自動繼承這個角色的權限

<br>

**❌ 問題**：所有 Pod 都能拿到相同的 IAM 權限！

<br>

就像你把所有辦公室的人都給了「總經理的門禁卡」一樣，風險超高！

<br>

### ✅ IRSA 的優勢

IRSA 讓你可以：

<br>

- 針對「某個特定 Pod（或 Service Account）」
- 指定它要用的 IAM Role
- 其他 Pod 都不會拿到這個權限

<br>

