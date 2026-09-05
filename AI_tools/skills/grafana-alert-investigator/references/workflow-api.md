# API / Ingress 類告警排查（成功率、延遲、錯誤率）

適用告警關鍵字：`Ingress Success Rate`、`Latency`、`Error Rate`、`5xx`、`P95/P99` 等。

## 排查步驟

1. **確認叢集與 datasource**：依 `references/environment-map.md` 解析 `market`/`env` label 找到對應的 Prometheus / Loki datasource UID。

2. **取得告警規則的原始定義（比只看 annotation 更準確）**：
   ```
   grafana-mcp-alerting_manage_rules operation=list search_rule_name=<告警標題關鍵字>
   grafana-mcp-alerting_manage_rules operation=get rule_uid=<找到的 uid>
   ```
   從回傳的 `data[].model.expr` 取得真正的 PromQL 條件式（例如成功率公式的分子分母），以及目前 `state`（normal 代表已恢復）。

3. **回放時間序列，找出異常時間窗與低點**：
   ```
   grafana-mcp-query_prometheus datasourceUid=<uid> expr=<從規則取出的完整運算式> queryType=range startTime=now-1h endTime=now stepSeconds=60
   ```
   同時可依 `by (status)` 拆解各狀態碼 rate，判斷是「錯誤增加」還是「總流量下降造成比例失真」。

4. **查 Loki AUDIT log 找出真正失敗的請求明細**：
   - 先確認 service label：`grafana-mcp-list_loki_label_values datasourceUid=<uid> labelName=service` 找出對應 namespace 名稱
   - 該专案若有 AUDIT log（格式通常為 `AUDIT UserId="x" Method="GET" Path="/api/xxx" Status=xxx DurationMs=xxx Ip="x.x.x.x"`），直接針對狀態碼過濾：
     ```
     grafana-mcp-query_loki_logs datasourceUid=<uid> logql={service="<ns>", container="<app>"} |= "AUDIT" |= "Status=400" startRfc3339=<開始> endRfc3339=<結束> limit=100
     ```
   - 針對每個關注的狀態碼（400/401/403/404/500/502/503/504）分別查詢，**不要用 or 語法一次查多個**（Loki logql 對 filter 字串用 `or` 語法容易 400 parse error，一次查一種較穩定）
   - 若單次查詢筆數達到 `limit`（如 100）且 `resultsTruncated` 為 true，代表還有更多，需分段縮小時間窗或加大 limit 重查以取得完整計數

5. **用 PowerShell 對存檔的 JSON 做分組統計**（因為 LogQL 無法直接對 log line 內的 JSON 欄位做 `sum by`）：
   ```powershell
   $json = Get-Content $path -Raw | ConvertFrom-Json
   $objs = $json.data | ForEach-Object { $_.line | ConvertFrom-Json }
   $objs | Group-Object { $_._props.IpAddress } | Select-Object Name, Count | Sort-Object Count -Descending
   $objs | Group-Object { $_._props.UserId } | Select-Object Name, Count
   ```
   統計面向至少包含：**IP、UserId、Path、StatusCode、次數、首末發生時間**。

6. **追根因**：挑一筆代表性的失敗請求，用其 `_tid`（trace id）或 RequestId 做關聯查詢，撈出同一個 trace 內的完整前後 log：
   ```
   grafana-mcp-query_loki_logs datasourceUid=<uid> logql={service="<ns>", container="<app>"} |= "<trace id 片段>" startRfc3339=<失敗時間前後幾秒>
   ```
   在結果中找 `_lvl=Error` 或 `_lvl=Warning` 的訊息，通常就是根因（例如上游 API 回傳錯誤、Session 過期、第三方服務錯誤等）。

7. **判斷是否為特定來源造成**：
   - 若錯誤集中在少數 IP/UserId，且都指向同一個資源 ID（如同一個直播場次、同一個訂單），代表是**資料層面的個案問題**（非系統性故障）
   - 若錯誤分散在大量不同 IP，且伴隨 5xx 或延遲增加，較可能是**系統性容量/效能問題**，需轉查 Worker 資源狀況（見 `workflow-worker.md`）

## 常見雷區
- Loki label 只有基礎欄位（如 `service`, `container`），詳細欄位（IP、Path、Status、UserId）都包在 log line 的 JSON 內，必須用 `|=` 字串過濾 + PowerShell 解析，無法用 label 過濾。
- `query_loki_logs` 的 `limit` 上限通常是 100，大量資料需分段查詢（縮小時間範圍）確保拿到完整筆數。
- Datasource UID 若查無資料，先用 `grafana-mcp-list_datasources` 確認名稱是否正確，不同市場/環境的 Loki/Prometheus 是分開的獨立 datasource。
