

## docker run -d -p80:80 --name mynginx nginx

```bash
abb6ea7d6050433dd3cc6b7097450c99990cb2b811a5071485a3fc6342a022dd docker: Error response from daemon: Ports are not available: exposing port TCP 0.0.0.0:80 -> 0.0.0.0:0: listen tcp 0.0.0.0:80: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
```

Docker port 80:80 綁定失敗

你的 container 想佔用電腦的 80 port，但這個 port 目前不能被 Docker 使用，所以 Nginx 雖然開始建立了，最後對外開門失敗。


錯誤出在這裡：

```bash
Ports are not available
listen tcp 0.0.0.0:80
```

意思是：Docker 想使用你主機的 80 port，但 Windows 不讓它綁定。


可以先改用另一個 port，例如 8080：

```bash
docker run -d -p8080:80 --name mynginx nginx
```

然後打開瀏覽器：http://localhost:8080



