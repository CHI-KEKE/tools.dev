---
name: mweb-s3-storage
description: >
  Guide for working with AWS S3 storage in the MobileWebMall (mweb) project
  (repo: nineyi.webstore.mobilewebmall, solution: NineYi.WebStore.MallAndApi.sln).
  Use when adding a new S3 bucket type, reading/writing files to S3,
  or wiring a new service that needs S3 access.
  Covers the full stack: TargetBucketEnum → AmazonFactory → S3StorageProvider → Service DI.
---

# [mweb] S3 Storage 操作指引

> ⚠️ **mweb 專案限定 Skill**
> 本 Skill 僅適用於 **`nineyi.webstore.mobilewebmall`（mweb）** 專案（solution: `NineYi.WebStore.MallAndApi.sln`）。
> 若工作目錄不在此專案下，請立即停止。

---

## 架構總覽

```
TargetBucketEnum          ← 定義 S3 Bucket 種類
    │
    ▼
IAmazonFactory            ← 提供 Region / Credentials / BucketName
(AmazonFactory)               讀取 IConfigService (AppSettings)
    │
    ▼
IAmazonS3ClientFactory    ← 建立 IAmazonS3 Client
(AmazonS3ClientFactory)
    │
    ▼
IS3StorageProvider        ← 對外操作介面：Upload / GetFile / TryGetFile / GetFileMetaData
(S3StorageProvider)
    │
    ▼
各 Service                ← 透過 Autofac 建構子注入 IS3StorageProvider
```

**核心檔案位置：**

| 檔案 | 路徑 |
|---|---|
| `TargetBucketEnum` | `WebStore/Frontend/BE/ThirdPartyApis/Amazon/Enums/TargetBucketEnum.cs` |
| `IAmazonFactory` | `WebStore/Frontend/BLV2/ThirdPartyApis/Amazon/IAmazonFactory.cs` |
| `AmazonFactory` | `WebStore/Frontend/BLV2/ThirdPartyApis/Amazon/AmazonFactory.cs` |
| `IAmazonS3ClientFactory` | `WebStore/Frontend/BLV2/ThirdPartyApis/Amazon/IAmazonS3ClientFactory.cs` |
| `AmazonS3ClientFactory` | `WebStore/Frontend/BLV2/ThirdPartyApis/Amazon/AmazonS3ClientFactory.cs` |
| `IS3StorageProvider` | `WebStore/Frontend/BLV2/ThirdPartyApis/Amazon/Storage/IS3StorageProvider.cs` |
| `S3StorageProvider` | `WebStore/Frontend/BLV2/ThirdPartyApis/Amazon/Storage/S3StorageProvider.cs` |
| `ServiceModule` | `WebStore/Frontend/BLV2/Modules/ServiceModule.cs` |

---

## Step 1：確認需求

收集以下資訊後再動手：

| 問題 | 影響 |
|---|---|
| **使用現有 Bucket 還是新 Bucket？** | 新 Bucket → 需走完 Step 2–3；現有 → 直接 Step 4 |
| **操作類型？** Upload / GetFile / TryGetFile / GetFileMetaData | 決定 `IS3StorageProvider` 要呼叫哪個方法 |
| **檔案不存在時要 throw 還是回傳 null？** | `GetFile` = throw；`TryGetFile` = return null |
| **目標路徑（Key）格式為何？** | e.g. `seo/{shopId}/page.json` |

---

## Step 2：新增 Bucket 種類（有新 Bucket 才需要）

### 2-1 新增 `TargetBucketEnum` 值

檔案：`WebStore/Frontend/BE/ThirdPartyApis/Amazon/Enums/TargetBucketEnum.cs`

```csharp
public enum TargetBucketEnum
{
    Osm,
    MWebPublic,
    SEOContent,
    MyNewFeature   // ← 新增
}
```

### 2-2 在 `AmazonFactory` 加入三個 switch case

檔案：`WebStore/Frontend/BLV2/ThirdPartyApis/Amazon/AmazonFactory.cs`

**GetRegion**（若 Region 與預設相同可省略，走 `default`）：
```csharp
case TargetBucketEnum.MyNewFeature:
    regionSetting = this._configService.GetAppSetting("MyNewFeature.S3.Region");
    break;
```

**GetCredentials**（若 AccessKey/SecretKey 與 OSM 相同可省略，走 `default`）：
```csharp
case TargetBucketEnum.MyNewFeature:
    return new BasicAWSCredentials(
        this._configService.GetAppSetting("MyNewFeature.S3.AccessKey"),
        this._configService.GetAppSetting("MyNewFeature.S3.SecretKey"));
```

**GetBucketName**（必填）：
```csharp
case TargetBucketEnum.MyNewFeature:
    return this._configService.GetAppSetting("MyNewFeature.S3.BucketName");
```

### 2-3 新增 AppSettings Config Key

在各環境的 config 檔（`WebStore/WebAPI/AppSettings.{Env}.config`）加入：
```xml
<add key="MyNewFeature.S3.Region"     value="ap-northeast-1" />
<add key="MyNewFeature.S3.AccessKey"  value="..." />
<add key="MyNewFeature.S3.SecretKey"  value="..." />
<add key="MyNewFeature.S3.BucketName" value="my-feature-bucket" />
```

**已有的 Config Key 對照表：**

| Bucket | Config Key 前綴 |
|---|---|
| `Osm`（default） | `AWS.OSM.S3.*` |
| `MWebPublic` | `AWS.MWeb.S3.Bucket.Public` |
| `SEOContent` | `PageSEOContent.S3.*` |

---

## Step 3：注入 IS3StorageProvider 至 Service

### 3-1 Service 建構子加入 `IS3StorageProvider`

```csharp
using NineYi.WebStore.Frontend.BLV2.ThirdPartyApis.Amazon.Storage;
using NineYi.WebStore.Frontend.BE.ThirdPartyApis.Amazon.Enums;

public class MyFeatureService : IMyFeatureService
{
    private readonly IS3StorageProvider _s3StorageProvider;

    public MyFeatureService(IS3StorageProvider s3StorageProvider)
    {
        this._s3StorageProvider = s3StorageProvider;
    }
}
```

> Autofac 會自動解析 `IS3StorageProvider` → `S3StorageProvider`，
> 不需要手動在 `ServiceModule.cs` 額外註冊 `IS3StorageProvider`。
> 僅有新增自己的 Service 實作時，才需要在 `ServiceModule.cs` 加上：
> ```csharp
> builder.RegisterType<MyFeatureService>().As<IMyFeatureService>();
> ```

---

## Step 4：呼叫 S3 操作

### 4-1 上傳（Upload）

**從 Stream 上傳：**
```csharp
using (var ms = new MemoryStream(fileBytes))
{
    this._s3StorageProvider.Upload(TargetBucketEnum.MyNewFeature, ms, "path/to/file.json");
}
```

**從本機路徑上傳：**
```csharp
this._s3StorageProvider.Upload(TargetBucketEnum.MyNewFeature, @"C:\local\file.json", "path/to/file.json");
```

### 4-2 取得檔案（GetFile）— 檔案必須存在，否則拋 `FileNotFoundException`

```csharp
using (var stream = this._s3StorageProvider.GetFile(TargetBucketEnum.MyNewFeature, "path/to/file.json"))
using (var reader = new StreamReader(stream))
{
    var json = reader.ReadToEnd();
    var entity = JsonConvert.DeserializeObject<MyEntity>(json);
}
```

### 4-3 安全取得檔案（TryGetFile）— 檔案不存在時回傳 null

```csharp
var stream = this._s3StorageProvider.TryGetFile(TargetBucketEnum.MyNewFeature, "path/to/file.json");
if (stream == null)
{
    // 檔案不存在，走 fallback 邏輯
    return null;
}
using (stream)
using (var reader = new StreamReader(stream))
{
    return JsonConvert.DeserializeObject<MyEntity>(reader.ReadToEnd());
}
```

### 4-4 取得 MetaData（GetFileMetaData）— 取不到時回傳 null

```csharp
var etag = this._s3StorageProvider.GetFileMetaData(
    TargetBucketEnum.MyNewFeature,
    "path/to/file.json",
    "x-amz-meta-custom-key");
```

---

## 錯誤處理規則

| 情境 | 正確做法 |
|---|---|
| 檔案一定存在、找不到屬於 bug | 使用 `GetFile`，讓 `FileNotFoundException` 向上傳遞 |
| 檔案可能不存在（正常 case） | 使用 `TryGetFile`，回傳 null 後走 fallback |
| AmazonS3Exception 需要靜默 | 使用 `TryGetFile` 或 `GetFileMetaData`（內建 catch） |
| Upload 失敗 | `Upload` 會拋 `ApplicationException("AWS S3 PutObject failed.")`，呼叫端需視情況 catch |

---

## 參考實作範例

完整範例可參考：
- `WebStore/Frontend/BLV2/SEO/PageSEOContentS3SourceProvider.cs`
  → 示範 `GetFile` + JSON 反序列化 + Redis Cache 搭配使用

---

## Final Verification

完成後確認：
1. `TargetBucketEnum` 有新增值（若新 Bucket）
2. `AmazonFactory` 的三個 switch 都有對應 case（若新 Bucket）
3. 所有環境 config 都補上 Key（Debug / QA / Prod）
4. Service 建構子有 `IS3StorageProvider` 參數
5. `TryGetFile` vs `GetFile` 使用正確（有無靜默 null 需求）
6. Build：`msbuild NineYi.WebStore.MallAndApi.sln /p:Configuration=Debug`
