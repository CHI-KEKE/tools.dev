


## step1

到 ngrok 官網下載 Windows 版並解壓縮後，會得到 ngrok.exe

放到你想放的位置（例如 C:\Tools\ngrok\ngrok.exe）

開啟 PowerShell / CMD，切到該資料夾（或把它加到 PATH）


## step2

ngrok config add-authtoken <你的token>

## tunnel

ngrok http https://localhost:5001


## 拿到公開網址，設定到外部 webhook

ngrok 跑起來後，你會看到類似：

Forwarding https://xxxxx.ngrok-free.app -> https://localhost:5001

你要把外部 webhook 的目標 URL 設成：

https://xxxxx.ngrok-free.app/<你的webhook路徑>

例如你本機 webhook endpoint 是：

POST https://localhost:5001/api/webhook/payment

那外部就填：

https://xxxxx.ngrok-free.app/api/webhook/payment



## 用 ngrok 的 Web UI 看 webhook 有沒有打進來（超好用）

ngrok 會提供本機檢視介面（通常是）：

http://127.0.0.1:4040

打開後你可以看到：

每一次 webhook request（headers/body）

轉送到你本機的結果（status code / response）





## 常見坑

坑 1：外部服務不接受自簽憑證？

外部其實只打到 ngrok 的公開 HTTPS（它是合法憑證），所以通常沒問題。
問題比較常出在 ngrok -> localhost 這段若你本機是自簽，ngrok 有時需要你指定 https://localhost:5001（上面情境 A）。

坑 2：你的 webhook endpoint 需要正確路徑、方法、Content-Type

外部 webhook 幾乎都是：

POST

Content-Type: application/json（或 form）
你本機 endpoint 要能接住。

坑 3：你在本機只綁定 127.0.0.1 或只允許特定 Host

ngrok 轉送時 Host header 可能不是 localhost。
可用：

ngrok http https://localhost:5001 --host-header=localhost
坑 4：ASP.NET Core 啟動後其實不是 5001

有時候 launchSettings 或環境會讓埠號變了。請以啟動時 console 顯示的 Listening URL 為準。


## 快速自測（不靠外部 webhook）

拿到 https://xxxxx.ngrok-free.app 後，你可以自己打：

curl -X POST https://xxxxx.ngrok-free.app/api/webhook/payment ^
  -H "Content-Type: application/json" ^
  -d "{\"hello\":\"world\"}"

（PowerShell 也可以用 Invoke-RestMethod）