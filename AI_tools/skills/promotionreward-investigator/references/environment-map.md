# 環境對照表（Promotion Console 專用）

Namespace 固定為 `prod-promotion-service`（各市場叢集皆同名）。若查無對應，動態查 `k8s-mcp-kubectl_context` operation=list / `grafana-mcp-list_datasources`。

| market | k8s context                         | Loki datasource UID | Prometheus UID |
|--------|--------------------------------------|----------------------|-----------------|
| TW     | eks-ap-northeast-1-tw-91app-io-v2    | ZIOlfD44k            | hxdP8t7Vz       |
| HK     | eks-ap-southeast-1-hk-91app-io-v2    | RjRcuuN4k            | dfHnWT74z       |
| MY     | eks-ap-southeast-1-my-91app-io-v2    | LZjWWydVz            | A7UiZTnVk       |

Loki service label 固定查詢：`{service="prod-promotion-service"}`（三個市場 datasource 內皆用此 label，資料互相獨立，不會混市場）。

DynamoDB Table 命名慣例：`{Market}_Prod_Loyalty_PromotionReward` / `{Market}_Prod_Loyalty_PromotionReward_Detail`（例如 MY 市場為 `MY_Prod_Loyalty_PromotionReward`）。

外部給點 API 網域慣例：`http://loyalty-api.internal.{market}.91app.io/LoyaltyPoint/GivingPoint`（market 為小寫，如 `my`、`tw`、`hk`）。
