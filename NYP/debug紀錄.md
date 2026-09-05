
去 k8s 撈 event log 才能看到所有的資訊
 docker pull am/imageName 可以測試問題 (可以去build那一步看位甚麼deploy那一步拉不到)
secret要記得塞values進去, 因為 aws-load-config 失敗原因是他要去拉secrets 結果沒有資料
如果有既有的cancary 失敗的服務 我們重新deploy會造成撞資源問題 要請 infra移除


5/11

- 自行移除 canary 壞掉的 deployment 就好了




ai code review
chart 下一層 : nine1-ai-code-review-api
chart:
servicename : AI-Code-Review
s3 : AI-Code-Review
secrets : Ai-Code-Review
image : nine1-ai-code-review-api
hosts : ai-code-review-service-io.qa.91dev.tw
ai-code-review-service-internal.qa.91dev.tw
metrics

name : nine1-ai-code-review-api-ingress-request-count
templateRef : nine1-ai-code-review-api-ingress-request-count
customMetrics : 
name :nine1-ai-code-review-api-ingress-request-count
query : 'rate(nginx_ingress_controller_requests{namespace="ingress-nginx", ingress="{{ ingress }}",exported_namespace="qa-ai-code-review"}[2m])'



pipeline

NineYi.Ai.CodeReview.Api




config

下一層 : AI-Code-Review




.gitlab-ci.yml

GLCI__NYS_FQDN : NineYi.Ai.CodeReview.Api


Dockerfile

nine1-devops-deployments.QA.json

name : AI-Code-Review
serviceName : AI-Code-Review
NAMESPACE : qa-ai-code-review
RELEASE_NAME :nine1-ai-code-review-api


＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝livebuy＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
chart 下一層 : nine1-livebuy-web-api
chart:
servicename : Nine1.Livebuy
s3 : 91APP-Live
secrets : 91APP-Live
image : nine1-livebuy-web-api
host: 91app-live-io.qa.91dev.tw
91app-live-internal.qa.91dev.tw
metrics

name : nine1-livebuy-web-api-ingress-request-count
templateRef : nine1-livebuy-web-api-ingress-request-count
customMetrics : 
name :nine1-livebuy-web-api-ingress-request-count
query : 'rate(nginx_ingress_controller_requests{namespace="ingress-nginx", ingress="{{ ingress }}",exported_namespace="qa-91app-live"}[2m])'









config

下一層 : 91APP-Live
pipeline

Nine1.Livebuy.Web.Api


.gitlab-ci.yml

GLCI__NYS_FQDN : Nine1.Livebuy.Web.Api


nine1-devops-deployments.QA.json

name : Nine1.Livebuy
serviceName : Nine1.Livebuy
NAMESPACE : qa-91app-live
RELEASE_NAME :　nine1-livebuy-web-api