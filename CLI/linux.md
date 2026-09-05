## 查詢並關閉佔用 4000 port 的進程

lsof -i :4000


## 砍 process

kill -9 <PID>

## 一行搞定（自動抓 PID 並關閉）


kill -9 $(lsof -t -i :4000)



如果沒有  lsof ，可以用  fuser ：

fuser -k 4000/tcp