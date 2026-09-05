
## 部署流程

CI/CD 是持續整合（Continuous Integration）與持續部署/交付（Continuous Deployment/Delivery）的流程。而 EKS 在這個流程中的角色是：

<br>

| 階段 | 說明 | EKS 的角色 |
|------|------|-----------|
| CI（持續整合） | 專案程式碼 push 到 GitHub/GitLab 後自動觸發建置與測試流程 | 無直接關係，但會用於之後部署 |
| CD（持續部署） | 成功建置後自動部署到實際的執行環境 | ✅ 通常部署的目標就是 EKS！ |
| 執行環境 | 提供穩定、高可用的容器環境 | ✅ EKS 上會跑你打包好的 Docker 映像（如 Web API、後台服務等） |

<br>

1. 開發者 Push 程式碼到 GitHub

<br>

2. GitHub Actions（或 GitLab CI、Jenkins）會自動：
   - 建置專案
   - 執行測試
   - 將映像推送到 ECR（Elastic Container Registry）

<br>

3. 之後會觸發 CD 流程（例如 Argo CD 或 Helm）

<br>

4. 把新的映像部署到 EKS 上的某個 Kubernetes Pod

<br>

### 簡單比喻

CI/CD 是建築流程與機具（自動化蓋房子）, EKS 是蓋好的基地（地皮 + 建好骨架），負責放你要蓋的房子（容器）

<br>