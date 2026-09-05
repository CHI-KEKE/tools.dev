


一支「OSM.Web（NineYi.Sms）」的 藍綠 / 滾動式部署腳本，外掛很多功能（Slack、AWS、HealthCheck），再用 Task 把「第一步、第二步、第三步」的流程寫好。



## 1️⃣ 工具 & Addins 區塊



## 2️⃣ ARGUMENTS & 全域變數設定

```csharp
var target = Argument("target", "Default");
var configuration = EnvironmentVariable("configuration") ?? "QA";

var deployPath = "D:\\Archives";
var settingsPath = EnvironmentVariable("settingsPath") ?? "\\\\TYO-JENKINS-M.nineyi.corp\\nineyi.configuration";
var deployToolsPath = EnvironmentVariable("deployToolsPath") ?? "D:\\Deployment";
var deployRegion = Argument("region", "TYO");
var deployMarket = Argument("market", "TW");
var instanceRole = Argument("instanceRole", "Web");

var disableSonarQube = EnvironmentVariable("disableSonarQube") ?? "false";
```

target：Cake 要跑哪一個 Task，預設是 "Default"
configuration：從環境變數讀進來（Jenkins 給的），沒給就當 "QA"
deployPath：下載 artifact & 解壓縮的地方。
settingsPath：設定檔（共用 config）所在的檔案路徑。
deployToolsPath：你們內部的部署工具程式放哪裡。
deployRegion：部署區域，例如 TYO。
deployMarket：市場，例如 TW。
instanceRole：要 deploy 的機器角色，預設 "Web"。
disableSonarQube：是否跳過 Sonar（這支看起來沒真的用到）。

這邊其實就是「Jenkins 傳進來的參數 + 預設值」。

## 3️⃣ PREPARATION：專案 & Slack & HealthCheck 設定

```csharp
var solutionName = "NineYi.Sms";
var serviceName = "OSM.Web";

var websitePath="WebSite\\WebSite";
var backupAndDeployKey="Sms";
```

這支 script 鎖定的是 NineYi.Sms / OSM.Web。

```csharp
var slackChannelList = new Dictionary<string, string>{
  {"Release", "#rd-release"},
  {"Monitor", "#-devops-sys-monitor"},
  {"BackendRD", "#test-webhook"}
};
```

預先定義好不同用途要通知的 Slack channel。
```csharp
var healthCheckDomainMapByMarket = new Dictionary<string, string>(){
  {"TW", "store.91app.com"},
  {"PX", "store.px.91app.tw"},
  {"MY", "osm2.91app.com.my"},
  {"HK", "store.91app.hk"},
};

var healthCheckPathList = new string[]{
    "api/health/check",
    "api/ops/healthcheck"
};
```

每個市場對應的 domain。
每台機器健康檢查要打的 path：
/api/health/check、/api/ops/healthcheck。
```csharp
var isDryRunHealthCheck = false;
var changeConfigRetryCount = 30;
var changeConfigRetryDelayMS = 300;
```

isDryRunHealthCheck：如果 true 就只 log，不丟例外。
changeConfigRetryCount：變更 ELB 設定的重試次數。
changeConfigRetryDelayMS：每次重試間隔 ms。



## 4️⃣ Setup：建立 BuildData

```csharp
Setup<BuildData>(setupContext => GetBuildData(solutionName, serviceName));
```

在 Cake 的 pipeline 開始前，會呼叫 GetBuildData：
把 solutionName、serviceName、configuration、market、branch 等資訊全部組成一個 BuildData 物件。之後所有 Task 的 .Does<BuildData> 都是吃這個 data

這裡最重要的是 BuildData 通常會包含

Environment（QA / STG / PROD）
Market
MachineKey
ServiceName、SolutionName
BranchName 等等


## 5️⃣ Functions：共用方法

####　5-1. DeployToInstances

```csharp
private void DeployToInstances(BuildData data, List<InstanceInfo> instanceList, bool deployOnly)
{
  EnsureDirectoryExists($"{deployPath}\\{data.MachineKey}\\{data.Market}");

  if(deployOnly == false){
    var donwloadPath = DownloadArtifact(...);

    CleanDirectories($"{deployPath}\\Downloads\\{...}");
    Unzip(donwloadPath, $"{deployPath}\\Downloads\\{...}");
  }

  foreach (var instance in instanceList)
  {
    Deploy(
      deployToolsPath,
      $"{deployPath}\\Downloads\\{...}",
      $"\\\\{instance.Name}\\{data.Environment}\\NineYi\\{backupAndDeployKey}",
      backupAndDeployKey
    );
  }
}
```

做的事：

建出存放 artifact 的資料夾。如果 deployOnly == false：從某個 ArtifactSource 下載壓縮檔（可能是 S3 / Nexus / Jenkins artifact，細節在 DownloadArtifact）。

清掉舊的解壓縮目錄。
解壓縮到 Downloads\{MachineKey}\{Market}\{SolutionName}。
對於每一台 instance　呼叫 Deploy(...)
把新的程式碼複製到 \\{instanceName}\{Environment}\NineYi\Sms
做備份、覆蓋、套 config，實際邏輯藏在 NineYi.Cake.Lib 的 Deploy。



#### 5-2. ParallelDeployToInstances

```csharp
public void ParallelDeployToInstances(BuildData data, List<InstanceInfo> instanceList)
{
  var deployJobList = new List<Task>();
  foreach(var instance in instanceList){
    var singleList = new List<InstanceInfo>(){ {instance} };
    deployJobList.Add(Task.Run(() => {
      DeployToInstances(data, singleList, true);
    }));
  }
  Task.WhenAll(deployJobList).Wait();
}
```

對每台機器 平行 執行 DeployToInstances。
注意這裡 deployOnly = true，表示 → 不會再重新下載 artifact，只做「複製到機器」


#### 5-3. AWS 機器組態 & 名稱

```csharp
private string GetInstanceComponentName(string market) { ... }
private string GetInstanceType(string market, string defaultInstanceType) { ... }
```
GetInstanceComponentName：不同市場用不同 component name。
GetInstanceType：HK 用 c6i.xlarge, MY 用 c6i.large，其它用預設。


#### 5-4. GetInstanceNameList

只是把 instance 名稱 join 成字串，拿來印 log / Slack。


#### 5-5. HealthCheck + InstanceSiteHealthCheck

```csharp
private void HealthCheck(BuildData data, List<InstanceInfo> instanceList) {
  var healthCheckDomain = healthCheckDomainMapByMarket[data.Market];
  InstanceSiteHealthCheck(instanceList, healthCheckDomain, healthCheckPathList);
}
```
InstanceSiteHealthCheck 具體做的事：

用 Dns.GetHostAddresses(instance.Name) 解析 IP。
對每個 healthCheckPath（兩條 path）：
建一個 Task 平行執行：
透過 PowerShell 的 Invoke-WebRequest：
Uri = http://{healthCheckDomain}/{healthCheckPath}
Proxy = http://{instance.IP}（意思是請求會經由該機器 proxy 出去，來測試那台機器）。

拿到結果的 StatusCode。

如果不是 200 → 丟 Exception。

簡單說：
對每台機器，用該機器當 Proxy 去打 store domain 的 health check。
不健康就直接讓整個 Task fail。



## 6️⃣ Global 變數 & 固定機器清單

```csharp
var instanceType = "c6i.xlarge";
var instanceList = new List<InstanceInfo>();
```

instanceType：預設 VM 型號。
instanceList：之後 Retrieve Machines 會填進來。


```csharp
var oregonInstanceList = new List<InstanceInfo> {
  new InstanceInfo {
    Name = "OGDR-OSM-Web1",
    Type = "t3.medium",
    DeployGroup = "red",
    DeployGroups = new List<string> { "red" },
    ELBGroup = "px_osm_web",
    Region = "OR"
  },
};
```

這是一個 固定的 OR (Oregon) 機器清單，給 Deploy All 用，跟主流程略微獨立。


## 7️⃣ Tasks：實際的部署流程

/*
Red (Internal Tests) -> Blue (前半) -> Green (後半)
*/

意思是機器分成三個 group

Red：Internal test 用
Blue：前半
Green：後半

整個 release 流程，是在這三組之間做「上線 / 下線 / 部署 / 健康檢查」。


#### 7-1. Task("Retrieve Machines")

```csharp
Task("Retrieve Machines")
  .Does<BuildData>(async (data) =>
{
  instanceList = await GetInstanceInfos(data.SolutionName, data.Market, data.MachineKey, instanceRole);
  Information(instanceList.Dump());
});
```

透過 GetInstanceInfos 去查你這次要 deploy 的所有機器：

按 SolutionName、Market、MachineKey、Role 去找。
每台機器會有 Name、DeployGroup、DeployGroups、ELBGroup、Region。
把結果存到 全域的 instanceList。
之後所有步驟都是基於這個 instanceList 做 group 切分。


7-2. Task("Internel test")

第一步：先把 後半（green） 上線，測試 OK 後，
再把一台（red / blue）下線，佈署新程式。

流程：

Slack 廣播「第一步開始」。

透過 GetInstanceComponentName & GetInstanceType 決定啟動的 EC2 類型。

StartInstance(...) → 把相關機器開機。

EnsureServersAreLive(instanceList) → 確認機器都 alive。

找出 greenGroup（DeployGroups 包含 "green" 的機器）。

HealthCheck(data, greenGroup) → 確認後半目前健康。

Register 後半進 ELB：

呼叫 RegisterInstanceToELB，最多 retry 30 * (最多20內部小重試) 次。

EnsureServersAreInELB(greenGroup) → 確認 ELB 掛載成功。

Thread.Sleep(120秒) → 等流量穩定。

找出 redGroup：

優先拿 DeployGroups 含 "red" 的機器

如果沒有 red，就 fallback 拿 "blue"

Slack：告知要先把這一批下線。

UnregisterInstanceFromELB → 把 redGroup 從 ELB 解除。

Thread.Sleep(180秒) → 等 ELB 清掉連線。

呼叫 DeployToInstances(data, redGroup, false)：

下載最新 artifact

解壓縮

部署到 redGroup 的實體。

7-3. Task("Internel test check")

驗證剛剛那台 / 那批（red / blue）是不是部署成功。

再找一次 redGroup（沒有 red 就拿 blue）。

HealthCheck(data, redGroup) → 確認剛部署那批站台起得來。

FetchTranslation(data, redGroup) → 應該是抓多國語系的翻譯檔回寫或 warm-up。

Slack 通知「第一步已完成」。

7-4. Task("Sync first half")

第二步：佈署前半（blue）機器。

流程：

Slack：「第二步開始，佈署前半機器」。

一樣：StartInstance → 開機 / EnsureServersAreLive。

找 greenGroup → HealthCheck，確認後半正常。

把 greenGroup 全部 RegisterInstanceToELB，掛進線上。

EnsureServersAreInELB(greenGroup)。

找出 blueGroup。

Slack：要下線 blueGroup。

把 blueGroup 從 ELB 下線。

Thread.Sleep(180秒) → 等流量 drain。

ParallelDeployToInstances(data, blueGroup)：

平行對每台 blue 機器部署。

這裡不會再下載 artifact，只是把同一份 code 複製到 blue 每一台。

7-5. Task("Online first half")

把剛部署好的前半（blue）上線，並把後半（green）暫時下線。

HealthCheck(blueGroup)。

FetchTranslation(blueGroup)。

Slack：告知「前半部署完成，準備上線」。

把 blueGroup 一台台 RegisterInstanceToELB。

EnsureServersAreInELB(blueGroup)。

找出 greenGroup。

Slack：要把 greenGroup 下線。

對每台 green UnregisterInstanceFromELB。

Slack：「第二步已完成，線上為新版程式」。

7-6. Task("Sync last half")

第三步：把後半（green）也換成新版本。

Slack：「第三步開始，開始佈署後半機器」。

找 greenGroup。

ParallelDeployToInstances(data, greenGroup) → 平行部署。

7-7. Task("Online last half")

把後半（green）部署完後重新上線。

HealthCheck(greenGroup)。

FetchTranslation(greenGroup)。

Slack：「後半部署完成，準備上線」。

為每台 green 呼叫 RegisterInstanceToELB。

EnsureServersAreInELB(greenGroup)。

Slack：「第三步已完成，今日 Release 結束」。

至此整個藍綠 / 滾動式更新結束：
前半 + 後半全部是新版程式。

7-8. Task("Turn off")

只做一件事：

把 greenGroup 從 ELB 下線（關閉後半）。

7-9. Task("Online Green Offline Blue")

類似「藍綠反轉」用的工具 Task：

把 greenGroup 上線（Register to ELB）。

確認 greenGroup 掛上 ELB。

等 30 秒 Warmup。

把 blueGroup 從 ELB 下線。

Slack：交換藍綠完成。

7-🔟 Task("Deploy All")
Task("Deploy All")
  .Does<BuildData>((data) =>
{
  ParallelDeployToInstances(data, oregonInstanceList);
});


專門對 oregonInstanceList（OGDR-OSM-Web1）做平行部署。

跟主流程（blue/green）比較獨立。

7-11. Task("Switch back")
Task("Switch back")
  .IsDependentOn("Online Green Offline Blue")
  .Does<BuildData>((data) => {
      SendSlack(data, $"*[{data.Market}]{data.ServiceName}* 進行藍綠交換已完成", slackChannelList["BackendRD"]);
  });


先跑 Online Green Offline Blue

然後發 Slack：「藍綠交換已完成」

7-12. Task("Default")
Task("Default")
  ;


不做任何事。

如果 Cake 沒傳 --target 或 target 指到 Default，就只會載入 Script 而已。

8️⃣ 最後：執行入口
RunTarget(target);


讀最前面 var target = Argument("target", "Default");

也就是 Jenkins / 手動執行時指定的 --target，會決定這支 script 跑哪一條流程。

🔚 總結一句話

這支檔案做的事，可以濃縮成：

「用 Cake 寫的一套 OSM.Web 藍綠 / 滾動式部署流程，
會從 AWS 叫機器起來 → 檢查健康 → 與 ELB 註冊 / 解註冊 → 下載 & 部署 Artifact → 發 Slack 通知。」

如果你接下來想問：

「那 QA / PROD 是在哪裡區分？」

「這支在 QA 跟 PROD 的行為差異是什麼？」

「這三步驟在實際操作 Jenkins 時會怎麼按？」