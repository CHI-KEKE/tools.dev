


## 拉新 redis-server 的 image

docker run -d --name redis-open -p 6379:6379 redis:7 redis-server --bind 0.0.0.0 --protected-mode no

## 進去自己 ping 自己

docker exec -it redis-open redis-cli PING


## 另一個 container」當外部

docker run --rm redis:7 redis-cli -h host.docker.internal -p 6379 PING


```bash
[ redis-cli container ]
        |
        | 連線 host.docker.internal:6379
        v
[ Host (你的電腦) ]
        |
        | docker -p 6379:6379
        v
[ redis-open container ]
        |
        v
[ redis-server ]
```