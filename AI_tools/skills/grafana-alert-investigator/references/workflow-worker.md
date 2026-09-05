# Worker / Container 類告警排查（重啟、OOM、CrashLoop、CPU/Memory）

適用告警關鍵字：`Restarted containers`、`OOMKilled`、`CrashLoopBackOff`、`CPU/Memory usage`、`Pod not ready` 等。

## 排查步驟

1. **確認叢集與 namespace**：依 `references/environment-map.md` 解析 `market` + `env` label 找到 k8s context；`service`/`namespace` label 找到 namespace。

2. **確認告警中的 Pod 現況**：
   ```
   k8s-mcp-kubectl_get resourceType=pods name=<alert 中的 pod 名稱> namespace=<ns>
   ```
   若回傳 `not_found`：代表該 Pod 已被取代（很可能是 Deployment rollout 汰換舊 Pod），**非必然異常**，需要進一步比對 Deployment revision。

3. **列出目前該 workload 所有 Pod**（用 label 或 name 關鍵字篩選 `-o wide`），確認：
   - 目前 Pod 的 `RESTARTS` 欄位是否為 0
   - `READY` 是否全部正常（例如 `1/1`）

4. **查看 Deployment 狀態**：
   ```
   k8s-mcp-kubectl_describe resourceType=deployment name=<deployment name> namespace=<ns>
   ```
   關注：
   - `deployment.kubernetes.io/revision` — revision 號提升代表有新版本部署
   - Image tag / `kubectl.kubernetes.io/restartedAt` annotation 的時間戳
   - `NewReplicaSet` 是否為 Ready，`OldReplicaSets` 是否已縮容到 0/0
   - `Conditions`：`NewReplicaSetAvailable` + `MinimumReplicasAvailable` 皆為 True 代表部署健康

5. **若懷疑是 OOM / CrashLoop（而非單純版本更新）**：
   - 查詢 events：`k8s-mcp-kubectl_get resourceType=events namespace=<ns> sortBy=.lastTimestamp`（輸出量大時存檔用 PowerShell 篩選 `involvedObject.name` 關鍵字）
   - 查詢容器 Terminated Reason：`kubectl_describe pod` 內的 `Last State: Terminated Reason: OOMKilled` 是關鍵證據
   - 查 Metrics（即時快照，非歷史趨勢）：
     ```
     k8s-mcp-kubectl_get resourceType=pods.metrics.k8s.io name=<pod> namespace=<ns> output=yaml
     ```
     比對 `usage.memory` / `usage.cpu` 對比 Deployment 中設定的 `Limits`，判斷是否逼近上限。
   - 若需歷史趨勢（判斷是否漸進式洩漏），改用 Prometheus 查 `container_memory_working_set_bytes` / `container_cpu_usage_seconds_total`（datasource 見 environment-map.md）。

6. **判斷結論的原則**：
   - Pod not_found + 新 ReplicaSet 健康 + revision 有變化 + 時間吻合 → **正常部署汰換，非異常**
   - 有 `OOMKilled` / 高 restart count 持續增加 / Memory usage 逼近 Limit → **資源問題，需建議調高 limit 或排查記憶體洩漏**
   - 無明顯版本異動、Restarts 持續增加但無 OOM 訊號 → 需查 App log 找 exception（用 `k8s-mcp-kubectl_logs`，注意此工具需要 `resourceType=pod`，大量輸出會存檔，需用 PowerShell/grep 篩選 Error/Exception/Fatal 關鍵字）

## 常見雷區
- `kubectl_logs` 呼叫時務必帶 `resourceType: pod`，否則會報 `Cannot read properties of undefined` 錯誤。
- 大型輸出（events、logs、describe）會自動存成暫存檔，記得用 `powershell` + `ConvertFrom-Json` 或 `grep`/`Select-String` 篩選，勿整份讀入。
