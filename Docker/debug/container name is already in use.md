

## docker run -d -p8080:80 --name mynginx nginx

```bash
docker: Error response from daemon: Conflict. The container name "/mynginx" is already in use by container "abb6ea7d6050433dd3cc6b7097450c99990cb2b811a5071485a3fc6342a022dd". You have to remove (or rename) that container to be able to reuse that name. See 'docker run --help'.
```


刪掉已存在的 Docker container

mynginx 這個名字已經被舊 container 佔走了，要先把舊的清掉，新的 container 才能用同一個名字


先看目前所有 container：

```bash
docker ps -a
```

刪掉舊的 mynginx：

```bash
docker rm mynginx
```

如果它還在執行中，先停掉再刪：

```bash
docker stop mynginx
docker rm mynginx
```

也可以直接強制刪除：

```bash
docker rm -f mynginx
```

然後重新跑：

```bash
docker run -d -p8080:80 --name mynginx nginx
```


