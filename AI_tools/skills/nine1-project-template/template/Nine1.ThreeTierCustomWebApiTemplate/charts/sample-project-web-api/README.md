<!-- <TODO:REPLACE> 請將 Sample-Project 替換為 <ORIGIN_NAME_W_UPPER> -->
# Sample-Project Chart
<!-- <TODO:REPLACE> 請將 Sample-Project 替換為 <ORIGIN_NAME_W_UPPER> -->
## Sample-Project
<!-- <TODO:REPLACE> 請將 Sample-Project 替換為 <ORIGIN_NAME_W_UPPER> -->
此目錄提供 `Sample-Project` 專案的 [Helm Chart](1)，用於部署至 Kubernetes。

關於 .net migration 計畫，相關工具 (如 CLI)， spec 及 pipeline 等資訊，請參考[文件][2].

## F.A.Q.

### Q: 為什麼沒有 `ConfigMap`？
* [根據 .Net Core Migration 專案規劃](3)，application config 會直接由 S3 下載，不會使用 K8s 的 [ConfigMap](4) 儲存。

### Q: 為什麼沒有 `Secret`？
* [根據 .Net Core Migration 專案規劃][3]，application secret (e.g. DB connection string) 會直接由 AWS Secrets Manager 下載，不會使用 K8s 的 [Secret](5) 儲存。

[1]: https://helm.sh/docs/
[2]: http://www.91dev.tw/nineyi.cli-spec/
[3]: http://www.91dev.tw/nineyi.cli-spec/v1alpha/codeTemplate/spec/config-spec/
[4]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/
[5]: https://kubernetes.io/docs/concepts/configuration/secret/
