# 環境對照表（market/env → k8s context / Grafana datasource）

用途：告警文字中的 `market=xx env=yy` 標籤，對應到實際查詢用的 k8s context 與 Grafana datasource UID，避免每次都要重新查詢 `kubectl_context list` / `grafana-mcp-list_datasources`。

**若下表查無對應項目，直接動態查詢**（`k8s-mcp-kubectl_context` operation=list，`grafana-mcp-list_datasources` type=loki/prometheus），查到後可將新結果補進本表，保持更新。

## Kubernetes Context

| market | env  | k8s context                              |
|--------|------|-------------------------------------------|
| tw     | prod | eks-ap-northeast-1-tw-91app-io-v2          |
| tw     | dev  | eks-ap-northeast-1-tw-91dev-tw-v2          |
| hk     | prod | eks-ap-southeast-1-hk-91app-io-v2          |
| hk/my  | dev  | eks-ap-southeast-1-hk-my-91dev-tw-v2       |
| my     | prod | eks-ap-southeast-1-my-91app-io-v2          |
| pay    | prod | eks-ap-northeast-1-pay-91app-io            |
| pay    | sandbox | eks-ap-northeast-1-pay-sandbox-91app-io |
| -      | rancher（監控/管理叢集） | eks-ap-northeast-1-rancher-91app-io |

Namespace 命名慣例：`prod-<service-name>` / `<market>-<service-name>`（例如 `prod-91app-live`、`prod-promotion-service`）。若不確定 service 對應哪個 namespace，用 `k8s-mcp-kubectl_get resourceType=namespaces` 列出全部後用關鍵字比對。

## Grafana Loki Datasource UID

| 名稱               | uid           | market/env |
|--------------------|---------------|------------|
| TW-Prod-Loki       | ZIOlfD44k     | tw / prod  |
| TW-PX-QA-Loki      | xV5Pve7Vz     | tw / qa    |
| TW-Pay-Prod-Loki   | MlF4piUVz     | pay / prod |
| TW-Pay-Sandbox-Loki| NHOX26NIz     | pay / sandbox |
| HK-Prod-Loki       | RjRcuuN4k     | hk / prod  |
| HK-MY-QA-Loki      | DMXHJrI4k     | hk,my / qa |
| MY-Prod-Loki       | LZjWWydVz     | my / prod  |

## Grafana Prometheus/Mimir Datasource UID

| 名稱                     | uid              | market/env |
|--------------------------|------------------|------------|
| TW-Prod-Prometheus       | hxdP8t7Vz        | tw / prod  |
| TW-Prod-Mimir            | defi7846hocu8c   | tw / prod（長期資料） |
| TW-PX-QA-Prometheus      | Cysbbc7Vk        | tw / qa    |
| TW-Pay-Prod-Prometheus   | ObUN8iUVz        | pay / prod |
| TW-Pay-Prod-Mimir        | denby7blts35sf   | pay / prod |
| TW-Pay-Sandbox-Prometheus| hRpDp6NSz        | pay / sandbox |
| HK-Prod-Prometheus       | dfHnWT74z        | hk / prod  |
| HK-MY-QA-Prometheus      | xzpqiTn4k        | hk,my / qa |
| HK-MY-QA-Ingress-Prometheus | xaF41cnVk    | hk,my / qa（ingress 專用） |
| MY-Prod-Prometheus       | A7UiZTnVk        | my / prod  |
| Global-Prometheus        | XJSFszRSz        | 跨區域彙總 |

## 常用 namespace 對照（依告警中常見 service label）

| service label 關鍵字 | namespace（HK/TW/MY 皆同慣例，前綴依市場叢集而定）|
|---|---|
| Promotion-Service    | prod-promotion-service |
| 91APP-Live           | prod-91app-live |
| Coupon-Service       | prod-coupon-service |
| Cart-Service         | prod-cart-service |

若告警 service label 不在上表，用 `k8s-mcp-kubectl_get resourceType=namespaces` 搜尋含相同關鍵字的 namespace。
