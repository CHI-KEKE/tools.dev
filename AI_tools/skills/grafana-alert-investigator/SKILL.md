---
name: grafana-alert-investigator
description: Investigate Grafana/Alertmanager alerting notifications (container restarts, ingress success rate drops, latency spikes, error rate/5xx, CPU/Memory/OOM alerts) by connecting live via k8s-mcp and grafana-mcp (Prometheus + Loki). Use when the user pastes an alert notification text (containing Labels like env/market/service/ingress/pod/container and Metric values), or asks to investigate/analyze/查/調查一個告警案件、alerting case、production incident. Produces a structured 現象/根因/建議 (symptom/root cause/recommendation) report backed by real query evidence, not speculation.
---

# Grafana Alert Investigator

## Overview

調查 Grafana Alertmanager 告警，透過 k8s-mcp（叢集狀態）與 grafana-mcp（Prometheus 時序 + Loki log）實際連線查證，產出有根據的調查報告。**絕不能只憑告警文字內容臆測結論**，所有結論都必須附上實際查詢到的證據。

## 工作流程

### 1. 解析告警文字
從使用者貼上的告警內容中擷取：
- `market`、`env`（決定要連哪個叢集/datasource）
- `service`、`ingress`、`container`、`namespace`、`pod`（決定查詢目標）
- 告警標題/Summary 關鍵字（決定案件類型）

### 2. 判斷案件類型
| 告警關鍵字 | 類型 | 對應排查手冊 |
|---|---|---|
| Restarted containers、OOMKilled、CrashLoopBackOff、CPU/Memory usage、Pod not ready | **Worker/Container 類** | `references/workflow-worker.md` |
| Ingress Success Rate、Latency、Error Rate、5xx、P95/P99 | **API/Ingress 類** | `references/workflow-api.md` |

若告警內容同時具備兩種特徵，或無法明確判斷類型，**先詢問使用者要從哪個角度切入**，不要自行假設。

### 3. 找到對應叢集與 datasource
查 `references/environment-map.md` 取得 market/env 對應的 k8s context、Loki datasource uid、Prometheus datasource uid。**查無對應項目時，動態查詢** `k8s-mcp-kubectl_context`（operation=list）或 `grafana-mcp-list_datasources`（type=loki/prometheus）找出正確值，並可建議使用者將新結果補進對照表。

### 4. 依案件類型執行排查
- Worker/Container 類：詳細步驟見 `references/workflow-worker.md`（Pod 狀態、Deployment revision、Events、Metrics、OOM 判斷）
- API/Ingress 類：詳細步驟見 `references/workflow-api.md`（Alert Rule 原始 PromQL、時序回放、Loki AUDIT log 統計、trace 關聯找根因）

排查過程中若遇到「調查方向的分岔點」（例如：要往系統性問題查，還是往個案資料問題查；要不要擴大查詢時間範圍），**主動跟使用者確認**，不要單方面決定。

### 5. 產出報告
依 `references/report-template.md` 的固定格式輸出：**現象 / 根因 / 建議**。API 類需附 Status Code 與來源（IP/UserId）統計表；Worker 類需附資源使用/重啟狀態表。開頭簡述實際使用了哪些 MCP 工具查證（展現非憑空推測）。

## 常見雷區（兩類型通用）
- `k8s-mcp-kubectl_get`/`kubectl_describe`/`kubectl_logs` 大量輸出會自動存成暫存檔，用 PowerShell（`Get-Content -Raw | ConvertFrom-Json`）或 `grep`/`Select-String` 篩選，不要整份讀入 context。
- `kubectl_logs` 必須帶 `resourceType: pod` 參數。
- Loki `logql` 中避免用 `or` 語法一次查多個條件（容易 400 parse error），單一狀態碼/關鍵字分開查詢較穩定。
- `query_loki_logs` 有 `limit` 上限（通常 100），資料多時需縮小時間範圍分段查詢以取得完整統計。
