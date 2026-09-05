

##  build


C:\91APP\AI_Devs\liveby\nine1.live.buy\src


dotnet build Nine1.Livebuy.Web.Api.sln

C:\91APP\AI_Devs\liveby\nine1.live.buy\src\Web\Nine1.Livebuy.Web.Api


## run

dotnet run


## 只 test 特定 service


dotnet test --filter "FullyQualifiedName~GetShoppingCartSalePageGiftProcessorTest"



## 只看錯誤

 dotnet build 2>&1 | Select-String -Pattern "\s*error\s" -CaseSensitive:$false



## 舊框架


$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"


 & $msbuild "C:\91APP\SCMAPIV2\nineyi.scm.apiv2\NineYi.Scm.ApiV2.sln"



 $msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"

& $msbuild .\nineyi.scm.apiv2.sln /p:Configuration=Debug




## publish


# 1. 進入 repo 根目錄
cd C:\91APP\AI_Devs\taskmanager\nine1.tools.windows-task-manager\src\WindowsTaskManager

# 2. 還原套件
dotnet restore
dotnet restore .\src\WindowsTaskManager\WindowsTaskManager.csproj

# 3. 發佈（Release 模式，輸出到 .\publish 資料夾）
dotnet publish C:\91APP\AI_Devs\taskmanager\nine1.tools.windows-task-manager\src\WindowsTaskManager\WindowsTaskManager.csproj -c Release -o C:\91APP\AI_Devs\taskmanager\deploy-ui

# 4. 確認發佈結果
Get-ChildItem .\publish

執行完後， .\publish  資料夾會包含  WindowsTaskManager.dll 、 WindowsTaskManager.exe 、 appsettings.json 、 user-roles.json  等檔案。

如果目標機器沒有安裝 .NET Runtime，改用自我裁量（self-contained）發佈：

dotnet publish .\src\WindowsTaskManager\WindowsTaskManager.csproj -c Release -r win-x64 --self-contained true -o .\publish