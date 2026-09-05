

## 


java.nio.file.FileSystemException: D:\ws\nineyi.configuration\serverDetailMaps.json: 
The process cannot access the file because it is being used by another process.





hudson.plugins.copyartifact.CopyArtifact.copyOne(CopyArtifact.java:634)


原始檔案：file:/D:/Jenkins/jobs/NineYi.Configuration/branches/master/builds/3753/archive/serverDetailMaps.json

目標檔案：D:\ws\nineyi.configuration\serverDetailMaps.json



✅ 成功取得 JenkinsfileMultiMarket 並載入 nineyi.jenkins.library@1.0.75-alpha-001

✅ 成功 checkout 分支 feature/VSTS8959-QA600-MY-Global-Develop，commit hash：faf0f533e6f0c5df3ec946ecb7becfe4e5f740a0

✅ 成功複製 nineyi.configuration » master 第 3753 次建置的 artifact 檔案（但發生錯誤）


❌ 在 Copy Artifact 步驟時出現檔案鎖定錯誤：
java.io.IOException: Failed to copy ...serverDetailMaps.json
Caused by: java.nio.file.FileSystemException ... being used by another process




NineYi.Configuration Repo 有一個檔案

serverDetailMaps.json

內容類似這樣


```json
{"NineYi.WebStore.MallAndApi":{"QA":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA","Machine":"TYO-QA-MWeb1"}],"QA3":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA3","Machine":"TYO-QA3-MWeb"}],"QA33":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA33","Machine":"TYO-QA33-MWeb"}],"QA4":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA4","Machine":"TYO-QA4-MWeb"}],"QA5":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA5","Machine":"TYO-QA5-MWeb"}],"QA6":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA6","Machine":"TYO-QA6-MWeb"}],"QA7":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA7","Machine":"TYO-QA7-MWeb"}],"QA8":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA8","Machine":"TYO-QA8-MWeb"},{"Environment":"QA","Region":"SG","Market":"HK","MachineKey":"QA8","Machine":"SG-HK-QA1-MWeb2"}],"QA9":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA9","Machine":"TYO-QA9-MWeb"}],"QA10":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA10","Machine":"TYO-QA10-MWeb"}],"QA11":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA11","Machine":"TYO-QA11-MWeb"}],"QA14":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA14","Machine":"TYO-QA14-MWeb"}],"QA201":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA201","Machine":"TYO-QA201-MWeb"}],"QA202":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA202","Machine":"TYO-QA202-MWeb"}],"QA203":[{"Environment":"QA","Region":"TYO","Market":"TW","MachineKey":"QA203","Machine":"TYO-QA203-MWeb"}],"PP":[{"Environment":"PP","Region":"TYO","Market":"TW","MachineKey":"PP","Machine":"TYO-PP-MWeb1"}],"Prod":[],"Prod.HK":[{"Environment":"Prod","Region":"SG","Market":"HK","MachineKey":"Prod.HK","M...
```


Jenkins 嘗試將 serverDetailMaps.json 複製到工作目錄時，該檔案被其他進程佔用，導致無法寫入（可能是：

該檔案正在被其他 Jenkins job 使用

被掃毒軟體或索引工具鎖住）





改法


✅ 方法一：加入 retry 或等待

修改 Jenkinsfile 的 CopyArtifact 區段，加上 retry 與延遲，以避免瞬間鎖定問題。

retry(3) {
    sleep(time: 5, unit: 'SECONDS') // 等待解除檔案鎖定
    step([
        $class: 'CopyArtifact',
        projectName: 'nineyi.configuration',
        filter: 'serverDetailMaps.json',
        selector: specific('3753')
    ])
}


✅ 方法二：避免不同 Job 同時存取同一檔案（最佳化）

改為複製至新的 temporary 資料夾（避免檔案名重複）：

def destPath = "tmp_config_${env.BUILD_ID}"
sh "mkdir -p ${destPath}"
sh "cp -f serverDetailMaps.json ${destPath}/"


✅ 方法三：排查鎖定來源

手動登入 Jenkins slave 機器（TYO-TW-JKCI-S2）：

handle.exe serverDetailMaps.json

Job 名稱：TS8959-QA600-MY-Global-Develop

Bitbucket branch：feature/VSTS8959-QA600-MY-Global-Develop

發送 Slack 頻道：rd-ci

使用 lib：nineyi.jenkins.library@1.0.75-alpha-001



