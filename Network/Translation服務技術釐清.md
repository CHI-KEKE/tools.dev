# Translation 服務技術釐清

> 釐清日期：2026-05-06  
> 對象：NineYi.Translation（`C:\91APP\Translation\NineYi.Translation`）

---

## 一、IP 限制機制（InternalIpAuthorizationMiddleware）

### 結論
**不是阻擋外部 IP，而是提供公司內部的「捷徑授權」。**

### 機制
同時符合以下兩個條件 → 自動以 Admin 身份繞過 Firebase 登入：

1. Request IP 在白名單內
2. `Authorization: Bearer {PermanentToken}`

```csharp
// Startup.cs
app.UseMiddleware<InternalIpAuthorizationMiddleware>();
app.UseAuthentication(); // Firebase
```

### 白名單 IP（appsettings.json）
| IP | 備註 |
|---|---|
| `118.163.107.187` | 公司 IP |
| `60.250.142.217` | 公司 IP |
| `60.250.142.219` | 公司 IP |

### Token 設定
| 環境 | Token |
|---|---|
| Production / Local | `internal-api-91app-forever-token` |
| Development | `dev-internal-api-91app-token` |

### 外部 IP 的行為
外部 IP **不會被擋**，只是無法走這條捷徑，仍需使用合法 Firebase JWT。

---

## 二、API 授權漏洞

### 沒有 `[Authorize]` 的 Controller（任何人可呼叫）

| Controller | Route | 無保護的 Endpoints |
|---|---|---|
| AdminController | `/api/translations/` | `health`, `version`, `timeout`, `roles` |
| ActivitiesControllerV3 | `/api/v3/activities` | `GET /`, `GET /Formatted`, `GET /actionnames` |
| BackupsControllerV3 | `/api/v3/backups` | `GET /difference` |
| TransferControllerV3 | `/api/v3/transfer` | `POST /FromPreTranslationToImport` |
| TranslateControllerV3 | `/api/v3/translates` | `GET /{text}/locales/{locale}` |
| SystemActivitiesController | `/api/v1/system-activities` | `GET /` |

### UserRepo.getRoles() Bug

```csharp
// ❌ 錯誤的程式碼
if (!string.IsNullOrEmpty("avc"))  // 永遠 true
{
    roles.Add(admins.Contains("jessewang@91app.com") ? ...);    // 寫死 email
    roles.Add(translators.Contains("jessewang@91app.com") ? ...); // 寫死 email
}

// ✅ 正確應該是
if (!string.IsNullOrEmpty(this.CurrentUserId))
{
    roles.Add(admins.Contains(this.CurrentUserId) ? RoleType.Admin : RoleType.User);
    roles.Add(translators.Contains(this.CurrentUserId) ? RoleType.Translator : RoleType.User);
}
```

**影響：所有人的 Role 判斷都依據 `jessewang@91app.com` 而非登入者本人，Role 授權機制失效。**

---

## 三、HTTP 503 分析

### 錯誤訊息
```
upstream connect error or disconnect/reset before headers.
retried and the latest reset reason: remote connection failure
```

### 來源
這是 **Envoy Proxy（Istio service mesh）** 特有的錯誤格式，不是應用程式回的。

### 可能原因（按優先順序）

**1. Port 不一致（高度懷疑）**

| 來源 | Port |
|---|---|
| Dockerfile | 未指定 `EXPOSE`，ASP.NET Core 預設 port `80` |
| `k8s/template/deploy.yaml` | `containerPort: 80` |
| `charts/values-tw-qa.yaml` | `servicePort: 50350` ⚠️ |
| `charts/values-tw-prod.yaml` | `servicePort: 50350` ⚠️ |

Helm chart 的 `servicePort: 50350` 若被設為 targetPort，會打不到實際在 port 80 的 container。

**2. readinessProbe 持續失敗**
```yaml
readinessProbe:
  httpGet:
    path: /api/translations/health?readness
    port: 80
```
若 Pod 啟動後 health check 失敗（MongoDB / Firebase 設定錯誤），Pod 不會加入 Service endpoints。

**3. Pod OOM / CrashLoop**  
Memory limit 1000Mi，`COMPlus_GCHeapHardLimit: 0x12C00000`（300MB）。

### 排查指令
```bash
kubectl get pods -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
kubectl get endpoints <service-name> -n <namespace>
kubectl describe svc <service-name> -n <namespace>
```

---

## 四、TLS 錯誤

### 錯誤訊息
```
Client network socket disconnected before secure TLS connection was established
```

### 與 503 的差別
| | 503 upstream error | TLS socket error |
|---|---|---|
| 發生層 | Envoy 打不到 Pod | TCP/TLS 握手就斷了 |
| HTTP Status | 503 | 無（連 HTTP 都沒到） |
| 原因 | Pod down / port 錯 | 連線被 reset、憑證問題、防火牆 |

---

## 五、外網 DNS 與連線分析

### nslookup 結果

**內網**
```
translation.qa.91dev.tw
→ private-ingress-alb.eks.91dev.tw
→ internal-private-eks-ingress-alb-1654285349.ap-northeast-1.elb.amazonaws.com
→ 10.50.45.132 / 10.50.40.7  （私有 IP，只有內網可達）
```

**外網**
```
translation.qa.91dev.tw
→ 35.201.120.17  （GCP Global Load Balancer）
```

### 直接打 IP 的結果

```bash
curl -v https://35.201.120.17/api/v3/projects
# curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to 35.201.120.17:443
```

### 錯誤鏈解析

```
外網 curl 打 35.201.120.17:443
    │
    ▼ TLS 握手
GCP Global Load Balancer
    ├── ❌ SSL cert 簽給 domain，不符合裸 IP → SSL_ERROR_SYSCALL
    └── 即使 TLS 通，無 Host header → CLB 找不到 backend → 回 503
```

**這個 503 是 GCP CLB 回的，Translation 應用根本沒收到 request。**

---

## 六、外網存取方式

### 取得 Firebase Token
1. 開啟 `translation.qa.91dev.tw`（需 VPN）並登入
2. F12 → Network → 任意 API request → 找 `Authorization: Bearer eyJ...`

### 帶 Token 呼叫
```bash
curl https://translation.qa.91dev.tw/api/v3/projects \
  -H "Authorization: Bearer eyJhbGci0iJSUzI1NiIsImtpZCI6..."
```

### 注意事項
| 項目 | 說明 |
|---|---|
| Firebase Token 有效期 | **1 小時**，過期回 401 |
| QA 環境 | 只能內網存取，**需 VPN** |
| Prod 環境 | `translation.91app.io` / `translation.io.91app.com` |

---

## 七、環境資訊

| 環境 | Domain | 備註 |
|---|---|---|
| QA | `translation.qa.91dev.tw` | 內網 ALB，需 VPN |
| Prod | `translation.91app.io` | GCP CLB |
| Prod (備用) | `translation.io.91app.com` | GCP CLB |
