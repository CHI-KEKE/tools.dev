# 📊 資料整理與處理指南

## 📖 目錄

- [1. 日誌資料清理](#1-日誌資料清理)
  - [1.1 NMQ Log 一次性取代](#11-nmq-log-一次性取代)
  - [1.2 正規表達式解析](#12-正規表達式解析)
  - [1.3 清理前後對比](#13-清理前後對比)
- [2. 交集資料集合](#2-交集資料集合)
  - [2.1 字串資料處理](#21-字串資料處理)
  - [2.2 集合交集運算](#22-集合交集運算)
- [3. 所有集合內容加上特定符號](#3-所有集合內容加上特定符號)
  - [3.1 資料格式化需求](#31-資料格式化需求)
  - [3.2 字串格式化處理](#32-字串格式化處理)
- [4. URL 編碼與解碼](#4-url-編碼與解碼)
  - [4.1 常見字元編碼處理](#41-常見字元編碼處理)
  - [4.2 完整編碼解碼範例](#42-完整編碼解碼範例)

---

## 1. 日誌資料清理

### 1.1 NMQ Log 一次性取代

#### 🎯 **應用場景**

在處理系統日誌時，我們經常需要移除重複的元數據（metadata），只保留核心的日誌訊息內容。NMQ (Message Queue) 系統產生的日誌通常包含時間戳記、伺服器名稱、追蹤ID等資訊，這些在分析時可能會造成干擾。

#### 📝 **完整程式碼範例**

```csharp
void Main()
{
    string logs = @"
【2025-05-20T06:09:45.5538265Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 匯出給點活動適用商品(料號) xlsx 檔案成功
【2025-05-20T06:09:45.6730623Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 刪除檔案：\\SG-HK-QA1-SCM2\Storage\Tmp\ExportRewardPromotionOuterId\BA2505201400001\BA2505201400001_6780__20250520140940.xlsx
【2025-05-20T06:09:45.6742188Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 匯出給點活動適用商品(料號)總筆數：4
【2025-05-20T06:09:45.6742856Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 匯出給點活動適用商品(料號)檔案名稱：BA2505201400001_6780__20250520140940.zip
【2025-05-20T06:09:45.6743295Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 匯出給點活動適用商品(料號)下載路徑：\\SG-HK-QA1-SCM2\Storage\Tmp\ExportRewardPromotionOuterId\BA2505201400001\BA2505201400001_6780__20250520140940.zip
【2025-05-20T06:09:45.6976695Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 更新作業執行狀態, status:Finish
【2025-05-20T06:09:45.7419984Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 新增錯誤清單明細, 筆數:0
【2025-05-20T06:09:45.7440429Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 尚有資料未處理, 發動 Task 繼續執行批次處理
【2025-05-20T06:09:45.7451041Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 taskData :{""BatchUploadId"":11878,""ProcessType"":""ByProcessCount"",""BatchUploadDataId"":0,""ProcessCount"":10,""UploadUser"":""allenlin@nine-yi.com""}
【2025-05-20T06:09:45.9828407Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 Create Task, Data: {""BatchUploadId"":11878,""ProcessType"":""ByProcessCount"",""BatchUploadDataId"":0,""ProcessCount"":10,""UploadUser"":""allenlin@nine-yi.com""}, Job: ExportRewardPromotionOuterIdTask
【2025-05-20T06:09:46.3979563Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 End BatchUploadTaskProcess
【2025-05-20T06:09:46.3980937Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 ::Finished
";

    string cleaned = Regex.Replace(logs, @"^【[^】]+】【[^】]+】【[^】]+】【[^】]+】\s*", "", RegexOptions.Multiline);

    Console.WriteLine("== 清理後 ==");
    Console.WriteLine(cleaned);
}
```

### 1.2 正規表達式解析

#### 🔍 **Regex 模式分解說明**

讓我們逐步分析這個正規表達式的組成：

```csharp
@"^【[^】]+】【[^】]+】【[^】]+】【[^】]+】\s*"
```

| 符號組合 | 說明 | 匹配內容 |
|----------|------|----------|
| `^` | 行首錨點 | 確保從行的開始位置匹配 |
| `【` | 字面字元 | 匹配中文方括號「【」 |
| `[^】]+` | 否定字元類 | 匹配一個或多個非「】」的字元 |
| `】` | 字面字元 | 匹配中文方括號「】」 |
| `\s*` | 空白字元 | 匹配零個或多個空白字元 |

#### 📋 **模式匹配對照表**

| 模式部分 | 對應日誌欄位 | 範例內容 |
|----------|-------------|----------|
| 第1個 `【[^】]+】` | 時間戳記 | `【2025-05-20T06:09:45.5538265Z】` |
| 第2個 `【[^】]+】` | 伺服器名稱 | `【SG-HK-QA1-NMQ1】` |
| 第3個 `【[^】]+】` | 追蹤ID/請求ID | `【5082d421-c6c3-4924-b097-a924bab2eeb2】` |
| 第4個 `【[^】]+】` | 使用者ID/會話ID | `【3528715】` |

#### ⚙️ **RegexOptions.Multiline 說明**

```csharp
RegexOptions.Multiline
```

- **作用**：讓 `^` 和 `$` 符號能夠匹配每一行的開始和結束
- **重要性**：如果沒有這個選項，`^` 只會匹配整個字串的開始，而不是每行的開始
- **實際效果**：確保每一行的日誌前綴都被正確移除

### 1.3 清理前後對比

#### 📊 **處理前的原始日誌**

```
【2025-05-20T06:09:45.5538265Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 匯出給點活動適用商品(料號) xlsx 檔案成功
【2025-05-20T06:09:45.6730623Z】【SG-HK-QA1-NMQ1】【5082d421-c6c3-4924-b097-a924bab2eeb2】【3528715】 刪除檔案：\\SG-HK-QA1-SCM2\Storage\Tmp\ExportRewardPromotionOuterId\BA2505201400001\BA2505201400001_6780__20250520140940.xlsx
```

#### ✨ **處理後的清理日誌**

```
匯出給點活動適用商品(料號) xlsx 檔案成功
刪除檔案：\\SG-HK-QA1-SCM2\Storage\Tmp\ExportRewardPromotionOuterId\BA2505201400001\BA2505201400001_6780__20250520140940.xlsx
匯出給點活動適用商品(料號)總筆數：4
匯出給點活動適用商品(料號)檔案名稱：BA2505201400001_6780__20250520140940.zip
匯出給點活動適用商品(料號)下載路徑：\\SG-HK-QA1-SCM2\Storage\Tmp\ExportRewardPromotionOuterId\BA2505201400001\BA2505201400001_6780__20250520140940.zip
更新作業執行狀態, status:Finish
新增錯誤清單明細, 筆數:0
尚有資料未處理, 發動 Task 繼續執行批次處理
taskData :{"BatchUploadId":11878,"ProcessType":"ByProcessCount","BatchUploadDataId":0,"ProcessCount":10,"UploadUser":"allenlin@nine-yi.com"}
Create Task, Data: {"BatchUploadId":11878,"ProcessType":"ByProcessCount","BatchUploadDataId":0,"ProcessCount":10,"UploadUser":"allenlin@nine-yi.com"}, Job: ExportRewardPromotionOuterIdTask
End BatchUploadTaskProcess
::Finished
```

---

## 2. 交集資料集合

### 2.1 字串資料處理

#### 🎯 **應用場景**

在資料分析時，我們經常需要處理包含大量產品編號、訂單號碼或其他識別碼的字串資料。這些資料可能來自不同的來源，需要進行清理和格式化，然後找出其中的交集部分。

#### 📝 **完整程式碼範例**

```csharp
void Main()
{
    string included = @"
    --IW7385,IW4988,IR5789,IX7001,IW7541,IN2390,IR5798,IG4049,IG4052,IV5658  
--IV8226,IR7103,IR7096,IR6244,IR6245,IN4352,IN8749,IN8745,IV8223,IV8224  
--IV8221,IN8703,IN4343,IN4372,HZ4268,HZ4269,H63102,IU4623,IP8974,IR5775  
--IR5791,IR5784,IN2389,IR5782,IW7536,IX7000,IY0104,IN2391,IH2886,IE5700  
--IH2887,IG4107,IG4105,IN4374,HY1249,IV7749,IN8682,IN4347,IN8756,IR6249  
--IR6250,IN8701,IZ3128,IV5644,IR7108,IV5647,IR7110,IN4342,IV5657,IR6251  
--IE3237,IG4026,IG4036,IG4037,IG4095,IE5662,IG4028,IE3239,IS8985,IS8984  
--IN2401,IN4375,IN4377,IV5555,IZ3168,IV5625,IR6265,IV7737,IN4353,IZ3123  
--IZ3124,IV5622,IR6268,IZ3122,IZ3121,IV7736,IN4335,IV5836,IR7106,IZ3126  
--H54025,HM8347,HM8337,HS2721,HM8338,HR1986,HQ5964,HQ5972,HQ5967,HQ3661  
--HN1966,HT4501,HN1976,HT2303,HN1974,HD3317,GN5938,HM8362,HM8333,HM8356  
--HM8357,HM8358,HM8366,HM8340,HM8361,HM8354,HM8348,HM8341,HF2143,HQ6510  
--HR1952,HQ3734,HQ3663,HR1932,HR1951,HR1929,HM5039,HN4328,HT2291,HM5038  
--FN3359,FN3358,HT4499,GV4198,GV4194,HN4312,GV0336,HN4320,HG6153,HM9347  
--HT4498,HT4490,GV2799,GV2794,HT4734,HM5036,HB3405,HH8895,HT4732,HM5035  
--IB8611,HG8604,HM9342,IK9360,IU4628,IU4621,IL6965,IL6964,IP7162,HP3126  
--ID5430,IG2934,IG2937,IG2936,IG3043,IG0804,IP7678,IP7677,IL2027,IL2046  
--IL2152,IP7687,H63021,IP7695,IP7698,IL2035,IL2033,IL2040,IJ9902,IJ9907  
--IJ9891,IJ9872,IJ9880,IJ9877,IJ9876,IN5161,IU4627,IN8053,HZ4267,HZ4266  
--GK2074,IP1857,IU4629,IU4630,IQ3396,IQ3394,IT7794,IF7789,IE9390,ID5429  
--IF7791,IF7788,IG2914,IF7787,IG5300,ID5431,IP8779,IP5589,IL2066,IJ9782  
--IQ1792,HY1251,IP7929,IL2164,H63059,IQ1798,IL2056,H63080,H44782,H44798  
--IT7522,IT7524,H63044,IA1438,H44800,IA1421,IL4619,IL2059,IQ2137,H63094  
--HD3306,H62984,IJ3142,H62979,H62978,H62977,H63110,H63099,H63095,FZ6424  
--FZ6423,FZ6402,FZ6403,IE9396,IF2347,FZ6401,IA1453,H63016,IA1428,H44802  
--H63067,H63066,IB4785,IB4780,HY1255,HQ3672,HQ3735,JN4884,JN4885,JN7192  
--JN7183,JP1147,JD2903,JX2462,JW4773,JQ2454,JD1763,JD1761,JD1759,JD1477  
--JD3518,JD1765,JI7087,JL8301,JL8295,IW0069,JM7845,JN4986,JN7038,JN4945  
--JM7812,JN4906,JN4907,JD3521,JD3523,JC6396,JI7083,JL8299,JL6880,JM5494  
--JM7818,JM7817,JN1728,JN1727,JP1144,JP1143,JP1152,JP1153,JP1150,JP1148  
--JW4667,JD2909,JD2905,JP4745,JW7355,JS1118,JS1111,JN4990,JD5999,JN4873  
--JN4879,JM7815,JN3751,JM3230,JN4882,JN3719,JN3704,JM3358,JH6028,JP0400  
--JE2017,JE2016,IY9275,JE4023,IY9274,IF1973,IH0865,IF2047,IF2046,IH0871  
--IW9995,IX0011,JN7832,IX0009,IW7459,IW7455,IW9994,IW9993,IW9999,JD9794  
--IW7492,JI9153,IY9278,JE2014,IY4079,IH0869,IF2040,IF2041,IR7100,IR7102  
--JE3434,IN4398,JE3433,IN4397,JD9791,JE3436,JE9281,JE9282,IW2472,JD9843  
--IX0402,IW2473,JI9096,IZ3173,IZ3172,JE2012,IY4083,IY4087,H62982,H62981  
--IH2551,IE1450,IF2025,JE3438,JD9788,IW7472,JE3442,JD9793,JE9274,JD9799  
--IW7471,IW0080,JD9825,IW0071,JD9796,JF0668,JD9795,JF3665,JI7451,JE0130  
--IW7382,IW7386,JC7569,JC7568,JC7572,JC7571,IW7387,IW7389,IW7390,JF6361  
--JN4887,JS3154,JS1116,JS1115,JS3155,JM7844,JN4904,JN4911,JN4910,JD5997  
--JD1479,JD1474,JD1480,JD1475,JH8062,KA9633,JW4626,JZ0717,JX4745,JX4744  
--JX4804,JX7292,JW7352,JW7351,KB2608,KB2607,KA9630,JV6776,JV6782,JM7854  
--JD6002,JR4216,JR4217,JR4225,JR4224,JR6645,JR6644,JR6656,JR6655,KA2308  
--KC3339,JM9041,JM9039,JV9721,KB9310,JW6219,KA2302,KA7141,JW4624,JW4623  
--JW4621,KA7128,JX7276,JX7281,JX7333,KB3692,KD4760,JX4754,JX4752,KC8356  
--JR4201,JS2457,JS2459,JR6657,JX8362,JV9669,JV9720,JV9722,JV9770,KB2077  
--JY4556,JY4555,JW7354,JW7353,KD4759,KD2555,KE2311,JR4199,JS2463,JX8305  
--JX8308,JX8327,JX8294
                ";

    // 將字串轉成 List<string>
    var includedlist = included
        .Split(new[] { '\r', '\n', ',' }, StringSplitOptions.RemoveEmptyEntries) // 切換行、逗號
        .Select(s => s.Trim()) // 去掉空白
        .Where(s => !string.IsNullOrWhiteSpace(s) && !s.StartsWith("--")) // 過濾掉空白與 "--"
        .ToList();

    var orderString = @"
    GW5473
ID2895
IZ0161
JI9073
JI9073
JI9073
JI9073
JI9073
JI9073
JJ4013
JJ4013
JJ4013
    ";

    // 轉成 List<string>
    var orderlist = orderString
        .Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries) // 用換行分割
        .Select(s => s.Trim()) // 去掉前後空白
        .Where(s => !string.IsNullOrWhiteSpace(s)) // 避免空字串
        .ToList();

    // 找出交集的項目
    var intersection = includedlist.Intersect(orderlist).ToList();

    // 輸出交集結果
    intersection.Dump(); // 如果你在 LINQPad 中使用，這會把結果印出來
}
```

### 2.2 集合交集運算

#### 🔍 **資料處理步驟解析**

| 步驟 | 處理內容 | 方法說明 |
|------|----------|----------|
| 1. 字串分割 | `Split(new[] { '\r', '\n', ',' })` | 以換行符號和逗號分割字串 |
| 2. 移除空白 | `Select(s => s.Trim())` | 去除每個項目前後的空白字元 |
| 3. 過濾條件 | `Where(s => !string.IsNullOrWhiteSpace(s))` | 排除空白項目和註解行 |
| 4. 交集運算 | `Intersect(orderlist)` | 找出兩個集合的共同項目 |

#### 📊 **資料清理規則**

| 過濾規則 | 說明 | 範例 |
|----------|------|------|
| 移除註解行 | `!s.StartsWith("--")` | 排除以 `--` 開頭的行 |
| 移除空白項目 | `!string.IsNullOrWhiteSpace(s)` | 排除空字串和純空白 |
| 去除前後空白 | `s.Trim()` | 移除項目前後的空格 |
| 移除重複項目 | `StringSplitOptions.RemoveEmptyEntries` | 分割時自動移除空項目 |

---

## 3. 所有集合內容加上特定符號

### 3.1 資料格式化需求

#### 🎯 **應用場景**

在資料庫查詢、API 呼叫或程式碼產生時，我們經常需要將原始的資料清單轉換成特定格式。最常見的需求是為每個項目加上引號，以便用於 SQL 的 IN 子句或其他需要字串格式的場景。

<br>

#### 📝 **完整程式碼範例**

```csharp
void Main()
{
	string rawSkus = @"
IW7385,IW4988,IR5789,IX7001,IW7541,IN2390,IR5798,IG4049,IG4052,IV5658  
IV8226,IR7103,IR7096,IR6244,IR6245,IN4352,IN8749,IN8745,IV8223,IV8224  
IV8221,IN8703,IN4343,IN4372,HZ4268,HZ4269,H63102,IU4623,IP8974,IR5775  
IR5791,IR5784,IN2389,IR5782,IW7536,IX7000,IY0104,IN2391,IH2886,IE5700  
IH2887,IG4107,IG4105,IN4374,HY1249,IV7749,IN8682,IN4347,IN8756,IR6249  
IR6250,IN8701,IZ3128,IV5644,IR7108,IV5647,IR7110,IN4342,IV5657,IR6251  
IE3237,IG4026,IG4036,IG4037,IG4095,IE5662,IG4028,IE3239,IS8985,IS8984  
IN2401,IN4375,IN4377,IV5555,IZ3168,IV5625,IR6265,IV7737,IN4353,IZ3123  
IZ3124,IV5622,IR6268,IZ3122,IZ3121,IV7736,IN4335,IV5836,IR7106,IZ3126  
H54025,HM8347,HM8337,HS2721,HM8338,HR1986,HQ5964,HQ5972,HQ5967,HQ3661  
HN1966,HT4501,HN1976,HT2303,HN1974,HD3317,GN5938,HM8362,HM8333,HM8356  
HM8357,HM8358,HM8366,HM8340,HM8361,HM8354,HM8348,HM8341,HF2143,HQ6510  
HR1952,HQ3734,HQ3663,HR1932,HR1951,HR1929,HM5039,HN4328,HT2291,HM5038  
FN3359,FN3358,HT4499,GV4198,GV4194,HN4312,GV0336,HN4320,HG6153,HM9347  
HT4498,HT4490,GV2799,GV2794,HT4734,HM5036,HB3405,HH8895,HT4732,HM5035  
IB8611,HG8604,HM9342,IK9360,IU4628,IU4621,IL6965,IL6964,IP7162,HP3126  
ID5430,IG2934,IG2937,IG2936,IG3043,IG0804,IP7678,IP7677,IL2027,IL2046  
IL2152,IP7687,H63021,IP7695,IP7698,IL2035,IL2033,IL2040,IJ9902,IJ9907  
IJ9891,IJ9872,IJ9880,IJ9877,IJ9876,IN5161,IU4627,IN8053,HZ4267,HZ4266  
GK2074,IP1857,IU4629,IU4630,IQ3396,IQ3394,IT7794,IF7789,IE9390,ID5429  
IF7791,IF7788,IG2914,IF7787,IG5300,ID5431,IP8779,IP5589,IL2066,IJ9782  
IQ1792,HY1251,IP7929,IL2164,H63059,IQ1798,IL2056,H63080,H44782,H44798  
IT7522,IT7524,H63044,IA1438,H44800,IA1421,IL4619,IL2059,IQ2137,H63094  
HD3306,H62984,IJ3142,H62979,H62978,H62977,H63110,H63099,H63095,FZ6424  
FZ6423,FZ6402,FZ6403,IE9396,IF2347,FZ6401,IA1453,H63016,IA1428,H44802  
H63067,H63066,IB4785,IB4780,HY1255,HQ3672,HQ3735,JN4884,JN4885,JN7192  
JN7183,JP1147,JD2903,JX2462,JW4773,JQ2454,JD1763,JD1761,JD1759,JD1477  
JD3518,JD1765,JI7087,JL8301,JL8295,IW0069,JM7845,JN4986,JN7038,JN4945  
JM7812,JN4906,JN4907,JD3521,JD3523,JC6396,JI7083,JL8299,JL6880,JM5494  
JM7818,JM7817,JN1728,JN1727,JP1144,JP1143,JP1152,JP1153,JP1150,JP1148  
JW4667,JD2909,JD2905,JP4745,JW7355,JS1118,JS1111,JN4990,JD5999,JN4873  
JN4879,JM7815,JN3751,JM3230,JN4882,JN3719,JN3704,JM3358,JH6028,JP0400  
JE2017,JE2016,IY9275,JE4023,IY9274,IF1973,IH0865,IF2047,IF2046,IH0871  
IW9995,IX0011,JN7832,IX0009,IW7459,IW7455,IW9994,IW9993,IW9999,JD9794  
IW7492,JI9153,IY9278,JE2014,IY4079,IH0869,IF2040,IF2041,IR7100,IR7102  
JE3434,IN4398,JE3433,IN4397,JD9791,JE3436,JE9281,JE9282,IW2472,JD9843  
IX0402,IW2473,JI9096,IZ3173,IZ3172,JE2012,IY4083,IY4087,H62982,H62981  
IH2551,IE1450,IF2025,JE3438,JD9788,IW7472,JE3442,JD9793,JE9274,JD9799  
IW7471,IW0080,JD9825,IW0071,JD9796,JF0668,JD9795,JF3665,JI7451,JE0130  
IW7382,IW7386,JC7569,JC7568,JC7572,JC7571,IW7387,IW7389,IW7390,JF6361  
JN4887,JS3154,JS1116,JS1115,JS3155,JM7844,JN4904,JN4911,JN4910,JD5997  
JD1479,JD1474,JD1480,JD1475,JH8062,KA9633,JW4626,JZ0717,JX4745,JX4744  
JX4804,JX7292,JW7352,JW7351,KB2608,KB2607,KA9630,JV6776,JV6782,JM7854  
JD6002,JR4216,JR4217,JR4225,JR4224,JR6645,JR6644,JR6656,JR6655,KA2308  
KC3339,JM9041,JM9039,JV9721,KB9310,JW6219,KA2302,KA7141,JW4624,JW4623  
JW4621,KA7128,JX7276,JX7281,JX7333,KB3692,KD4760,JX4754,JX4752,KC8356  
JR4201,JS2457,JS2459,JR6657,JX8362,JV9669,JV9720,JV9722,JV9770,KB2077  
JY4556,JY4555,JW7354,JW7353,KD4759,KD2555,KE2311,JR4199,JS2463,JX8305  
JX8308,JX8327,JX8294
";
	// 轉換處理
	var result = rawSkus
		.Split(new[] { '\r', '\n', ',' }, StringSplitOptions.RemoveEmptyEntries) // 切開換行與逗號
		.Select(s => s.Trim()) // 去掉空白
		.Where(s => !string.IsNullOrWhiteSpace(s)) // 過濾空白項
		.Select(s => $"\'{s}\'") // 加上單引號
		.ToList();

	// 合併成一個字串
	string output = string.Join(",", result);

	// 印出結果
	Console.WriteLine(output);
}
```

### 3.2 字串格式化處理

#### 🔧 **資料轉換流程**

| 處理步驟 | LINQ 方法 | 作用說明 |
|----------|-----------|----------|
| 1. 分割原始資料 | `Split(new[] { '\r', '\n', ',' })` | 以換行符號和逗號切割字串 |
| 2. 移除空項目 | `StringSplitOptions.RemoveEmptyEntries` | 自動排除分割後的空項目 |
| 3. 清理空白字元 | `Select(s => s.Trim())` | 移除每個項目前後的空白 |
| 4. 過濾無效項目 | `Where(s => !string.IsNullOrWhiteSpace(s))` | 確保沒有空白或null項目 |
| 5. 加上格式符號 | `Select(s => $"\'{s}\'")` | 為每個項目加上單引號 |
| 6. 合併為字串 | `string.Join(",", result)` | 用逗號連接所有項目 |

<br>

#### 💡 **實際應用範例**

**處理前的原始資料：**
```
IW7385,IW4988,IR5789,IX7001,IW7541
IV8226,IR7103,IR7096,IR6244,IR6245
```

**處理後的格式化結果：**
```
'IW7385','IW4988','IR5789','IX7001','IW7541','IV8226','IR7103','IR7096','IR6244','IR6245'
```

**SQL 查詢應用：**
```sql
SELECT * FROM Products 
WHERE ProductCode IN ('IW7385','IW4988','IR5789','IX7001','IW7541')
```

<br>

#### 🛠️ **其他格式化選項**

| 格式需求 | 程式碼修改 | 輸出結果 |
|----------|------------|----------|
| 雙引號格式 | `Select(s => $"\"{s}\")` | `"IW7385","IW4988"` |
| 方括號格式 | `Select(s => $"[{s}]")` | `[IW7385],[IW4988]` |
| 大括號格式 | `Select(s => $"{{{s}}}")` | `{IW7385},{IW4988}` |
| 前綴格式 | `Select(s => $"SKU_{s}")` | `SKU_IW7385,SKU_IW4988` |

---

## 4. URL 編碼與解碼

### 4.1 常見字元編碼處理

#### 🎯 **應用場景**

在 Web 開發過程中，URL 參數傳遞、API 呼叫或資料傳輸時，經常需要對包含特殊字元的字串進行編碼處理。這包括空格、中文字元、特殊符號等，以確保資料在網路傳輸過程中的完整性和正確性。

<br>

#### 📝 **完整程式碼範例**

```csharp
void Main()
{
    var samples = new[]
    {
        "A B",          // 空格
        "Tom&Jerry",    // &
        "台灣",         // 中文
        "a=b",          // =
        "100%",         // %
        "C#",           // 特殊符號
        "hello+world"   // 加號
    };

    foreach (var sample in samples)
    {
        var encoded = Uri.EscapeDataString(sample);
        Console.WriteLine($"原始: {sample} → 編碼後: {encoded}");
    }
}
```

#### 🔍 **字元編碼對照表**

| 原始字元 | 編碼後結果 | 說明 |
|----------|------------|------|
| 空格 ` ` | `%20` | 空格字元轉換為百分號編碼 |
| `&` | `%26` | 避免與 URL 參數分隔符混淆 |
| `=` | `%3D` | 避免與 URL 參數賦值符混淆 |
| `%` | `%25` | 百分號本身需要編碼 |
| `+` | `%2B` | 加號在 URL 中有特殊意義 |
| 中文字 | `%E5%8F%B0%E7%81%A3` | UTF-8 編碼的百分號表示 |

### 4.2 完整編碼解碼範例

#### 🔄 **雙向轉換處理**

```csharp
void Main()
{
    var original = "台灣 A&B=100%";

    // 編碼
    var encoded = Uri.EscapeDataString(original);
    Console.WriteLine($"原始字串: {original}");
    Console.WriteLine($"編碼後: {encoded}");

    // 解碼
    var decoded = Uri.UnescapeDataString(encoded);
    Console.WriteLine($"解碼還原後: {decoded}");
}
```

#### 📊 **編碼解碼流程表**

| 處理階段 | 使用方法 | 輸入範例 | 輸出結果 |
|----------|----------|----------|----------|
| URL 編碼 | `Uri.EscapeDataString()` | `台灣 A&B=100%` | `%E5%8F%B0%E7%81%A3%20A%26B%3D100%25` |
| URL 解碼 | `Uri.UnescapeDataString()` | `%E5%8F%B0%E7%81%A3%20A%26B%3D100%25` | `台灣 A&B=100%` |

<br>

#### 💡 **實際應用場景**

**Web API 參數傳遞：**
```csharp
string searchKeyword = "C# 程式設計";
string encodedKeyword = Uri.EscapeDataString(searchKeyword);
string apiUrl = $"https://api.example.com/search?q={encodedKeyword}";
// 結果: https://api.example.com/search?q=C%23%20%E7%A8%8B%E5%BC%8F%E8%A8%AD%E8%A8%88
```

**文件下載路徑處理：**
```csharp
string fileName = "報表_2024年.xlsx";
string encodedFileName = Uri.EscapeDataString(fileName);
string downloadUrl = $"https://files.example.com/download/{encodedFileName}";
```

#### ⚠️ **注意事項**

| 項目 | 說明 | 建議做法 |
|------|------|----------|
| 編碼時機 | 僅對 URL 參數值進行編碼 | 不要對整個 URL 進行編碼 |
| 中文處理 | UTF-8 編碼可能產生較長字串 | 考慮使用 Base64 編碼替代方案 |
| 特殊字元 | 某些字元在不同環境有不同處理 | 測試驗證編碼結果的正確性 |
| 效能考量 | 頻繁編解碼可能影響效能 | 考慮快取編碼結果 |