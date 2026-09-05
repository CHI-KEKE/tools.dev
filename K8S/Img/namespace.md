## Namespace 的資源上限需要調整

```bash
pods "promotion-web-api-76d9db5667-8wxfr" is forbidden: exceeded quota: default-4w42q, requested: limits.cpu=2250m, used: limits.cpu=7250m, limited: limits.cpu=8:Deployment does not have minimum availability.
```

https://91app.slack.com/archives/CJHPX1DGF/p1746165782611889

- 先把 hk-qa-promotion-service 的 Namespace 的資源上限增加一倍了，目前看服務有成功啓動了



## namespace 維度看資源

- request 下降
- Node 數量未減少
- Throttled 較常出現
- 有遇到 Limits 沒有正常套用的情形，目前在 rancher 手動調整
- CPU request 下降3% (72->69) 總 node 未下降
- chart 檔 limits 需使用 pipeline v1.3.3-stable


https://monitoring-dashboard.91app.io/d/a50aa422-2c0e-44f0-b6bd-e4b8624c10eb/playground-cost?orgId=2&from=now-7d&to=now&timezone=Asia%2FTaipei&var-MarketENV=HK-Prod&var-Cluster=dfHnWT74z&var-Namespace=prod-promotion-service&var-Deployment=promotion-console-changestream&var-Pods=$__all&var-Cronjob=audit-2hour-promotion-engine-sync-collection-job&var-Meta_Namespace=cluster-log-shipper&var-Meta_Namespace=prod-api-gateway&var-Meta_Namespace=prod-api-token&var-Meta_Namespace=prod-appgen&var-Meta_Namespace=prod-audience&var-Meta_Namespace=prod-bff&var-Meta_Namespace=prod-bfo&var-Meta_Namespace=prod-campaign&var-Meta_Namespace=prod-cart-service&var-Meta_Namespace=prod-cms&var-Meta_Namespace=prod-commentservice&var-Meta_Namespace=prod-commerce-nmqv3&var-Meta_Namespace=prod-coupon-service&var-Meta_Namespace=prod-data-sync&var-Meta_Namespace=prod-e-voucher-service&var-Meta_Namespace=prod-erp-akki&var-Meta_Namespace=prod-erp-portal&var-Meta_Namespace=prod-logistics-center&var-Meta_Namespace=prod-loyalty-service&var-Meta_Namespace=prod-marketing-cloud-service&var-Meta_Namespace=prod-member-storefront-service&var-Meta_Namespace=prod-memberservice&var-Meta_Namespace=prod-membership&var-Meta_Namespace=prod-nc&var-Meta_Namespace=prod-nmqv3&var-Meta_Namespace=prod-notification-template&var-Meta_Namespace=prod-ns&var-Meta_Namespace=prod-offlineorder&var-Meta_Namespace=prod-promocode-pool&var-Meta_Namespace=prod-promotion-service&var-Meta_Namespace=prod-rate-limiter&var-Meta_Namespace=prod-rcs&var-Meta_Namespace=prod-regular-purchase-service&var-Meta_Namespace=prod-salepage-admin-service&var-Meta_Namespace=prod-salepage-listing-service&var-Meta_Namespace=prod-salepage-service&var-Meta_Namespace=prod-search&var-Meta_Namespace=prod-session-management&var-Meta_Namespace=prod-shopping-service&var-Meta_Namespace=prod-sso-provider&var-Meta_Namespace=prod-tag&var-Meta_Namespace=prod-webhook-sender&var-Meta_Namespace=prod-workflow