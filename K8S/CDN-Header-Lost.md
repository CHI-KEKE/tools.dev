## CDN → ALB → EKS Header 遺失排查

透過 CDN 打 API 後，Header 在抵達 Pod 前消失的排查流程。

<br>

#### 架構路徑

```
Client → CloudFront (CDN) → ALB → EKS Ingress → Pod
```

Header 在這條路徑的任一節點都可能被丟棄。

<br>

#### Step 1 — CloudFront Origin Request Policy（最常見）

CloudFront 預設**不轉發**大多數自訂 Header，必須明確設定。

**Console 路徑：**
```
CloudFront → Distributions → 選 Distribution
→ Behaviors → 選 Path Pattern → Edit
→ Cache key and origin requests
  → Origin request policy
```

> ⚠️ **Cache policy** 與 **Origin request policy** 是不同的，要看的是 **Origin request policy**

常見的 Webhook / API Header 需要手動加入：

| Header | 用途 |
|--------|------|
| `X-GitHub-Event` | GitHub Webhook 事件類型 |
| `X-Hub-Signature-256` | GitHub Webhook HMAC 驗證 |
| `X-Gitlab-Event` | GitLab Webhook 事件類型 |
| `X-Gitlab-Token` | GitLab Webhook Token 驗證 |
| `Authorization` | API 授權（CloudFront 預設不轉發） |

**處理方式：**
- 建立自訂 Origin request policy，把所需 Header 全部加進去
- 或改用內建 `Managed-AllViewer` policy（轉發所有 Header，但會影響快取效率）

<br>

#### Step 2 — ALB Listener Rules

**Console 路徑：**
```
EC2 → Load Balancers → 選 ALB
→ Listeners → 查 Rules
```

確認 Rules 中沒有 `remove header` action，ALB 本身通常不會主動刪除 Header。

<br>

#### Step 3 — EKS Ingress Controller Annotations

如果使用 **AWS Load Balancer Controller**（ingress class: alb），檢查 Ingress yaml：

```bash
kubectl get ingress -n <namespace> -o yaml
```

確認沒有影響 Header 的 annotation：

```yaml
# 這類 annotation 可能操作 Header
alb.ingress.kubernetes.io/actions.*
```

<br>

#### Step 4 — 快速診斷：直接看 Pod 收到的 Header

**方法 1：.NET API 加暫時性 Log**

```csharp
// Middleware 或 Controller 裡加這段 debug log
var headers = Request.Headers.Select(h => $"{h.Key}={h.Value}");
_logger.LogInformation("Received headers: {Headers}", string.Join(", ", headers));
```

**方法 2：kubectl exec 進 Pod curl 打自己**

```bash
kubectl exec -it <pod-name> -n <namespace> -- curl -v http://localhost:<port>/api/ping
```

**方法 3：部署 httpbin 測試 Pod**

```bash
# 部署 httpbin
kubectl run httpbin --image=kennethreitz/httpbin --port=80 -n <namespace>

# 打 /headers endpoint，可以直接看 Pod 實際收到的所有 Header
curl https://<your-domain>/headers
```

<br>

#### 常見案例對照

| Header 消失位置 | 現象 | 解法 |
|---------------|------|------|
| CloudFront | Pod log 完全看不到自訂 Header | 在 Origin request policy 加入該 Header |
| CloudFront | `Authorization` 不見 | 同上，`Authorization` CloudFront 預設不轉發 |
| ALB | Header 有但值被改 | 檢查 Listener Rules 的 header action |
| Ingress | Header 到 ALB 有但進不了 Pod | 檢查 Ingress annotations |
