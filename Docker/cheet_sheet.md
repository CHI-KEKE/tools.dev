
## docker image rm yoyo/myweb



## docker image tag yoyo/myweb yoyo88147/myweb:latest

## docker run -d

啟動一個容器 -d 表示在背景執行（daemon mode），不佔著你的 terminal

## --name redis-open

幫容器取名字，之後可以用 docker logs redis-open、docker stop redis-open 來操作，不用每次找那串又臭又長的 container id

## -p 6379:6379

把「主機的 6379 port」轉接到「容器內的 6379 port」結果是可以直接用 localhost:6379 連到 Redis

## redis:7

使用官方 Redis 7 的 image, 版本明確，行為可預期（不會哪天被升版雷到）

## redis-server --bind 0.0.0.0 --protected-mode no

這是「覆寫」Redis 預設啟動參數, 告訴 Redis：

- --bind 0.0.0.0：不要只聽 localhost，所有網卡都聽，允許任何 IP 連進來
- --protected-mode no：關掉 Redis 的保護模式，不檢查來源、不要求密碼，「誰連得進來誰就能用」


## docker exec -it redis-open

docker exec 表示對「已經在跑的 container」下指令，跟 docker run 不一樣，這裡不會新開容器

redis-open 指定目標容器, Docker 會去找這個名字對應的 container

## -it

-i：保持輸入（stdin）
-t：配置一個終端機

合在一起就是「讓你可以互動」

## --rm

指令跑完就自動刪掉 container，不留垃圾、不佔資源，非常適合「測試用容器」

## -h host.docker.internal

host.docker.internal，是 Docker 提供的特殊 DNS 名稱，讓 container 可以找到「宿主機本身」，在 container 裡，回頭打 host 的 6379 port

## docker rm -f redis-open

不管容器現在活著還是卡住，直接「結束它並清乾淨」，讓環境立刻回到可控狀態

- docker rm : 告訴 Docker 我要刪掉一個容器, 但前提是容器必須是已停止狀態
- -f（force）: 等同於幫你先做 docker stop, 就算容器正在跑、卡住、沒回應，也會直接 SIGKILL
- redis-open : 指定要被處理的容器名稱 Docker 會依這個名字找到對應的 container ID

## --requirepass "MyStrongPass123"

設定 Redis 密碼 之後必須 AUTH 才能操作
所有操作前，先確認你是「被允許的人」