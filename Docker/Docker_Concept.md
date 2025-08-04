# Docker 概念

## 目錄
- [Image Layer](#image-layer)
- [網路](#網路)

<br><br>

---

## Image Layer

image 是一個「唯讀」的模板, 所以會發生在第一個 container 中新增了一個 AAA.txt，但後來啟動的第二個 container 中並沒有看到這個檔案

<br>

這是因當我們從 image 啟動一個 container 時候，Docker 會載入這個 image 作為唯讀層，並且在上面加上一個可寫層，而我們在這個 container 中的操作實際上就是發生在這個可寫層中

<br>

![alt text](./image-3.png)

<br>

當我們 commit 後會形成新的 layer

<br>

```bash
docker container commit CONTAINER_ID [Repository:[Tag]]
```

<br>

![alt text](./image-4.png)

<br>

雖然我們在電腦中目前有 node:20 與 node:20-updated 兩個不同的 image，不過 Docker 並不會重複存兩個 node:20 ，也就是重複的部分 Docker 只會存一個，這樣就大大的節省了空間，此外也可以理解為什麼要作成唯讀了，唯讀能做到共用而不互相影響

<br>

當然，原本我們從 Docker Hub 上拉下來的 node:20 也不會只有單獨一層，所以當我們在 pull 這個 image 時，會看到的畫面是像下面這樣

<br>

![alt text](./image-5.png)

<br>

按照這個過程，node:20 至少是由 8 個 layer 構成的。

<br><br>

---

## 網路

### 列出 Docker 網路

docker network ls 這個指令來查看目前的網路有哪些

<br>

![alt text](./image-8.png)

<br>

bridge 網路（驅動是 bridge）是 Docker 預設採用的網路，也就是當我們在啟動 container 時，如果沒有指定使用哪一個網路，預設就是用這一個，所以其實我們到目前為止啟動的 container 都是用 bridge 這種網路驅動。

<br>

Docker 在啟動時，會透過 Linux 的 bridge 機制自動建立一個名為 docker0 的虛擬橋接器 (bridge)。所有連到這個預設網路的 Container，會被分配在同一個 Layer-2 区段 (subnet) 中，彼此可直接通訊。

<br>

### 檢視預設 bridge 網路詳細資訊

執行 docker network inspect bridge 可以看到 containers

<br>

![alt text](./image-9.png)

<br>

建立的兩個 alpine containers 被列在這裡了。此外，也可以看到其 subnet 為 "172.17.0.0/16"，而我們用 bridge 這個網路建立出來的 container 的 ip 也是在這個 subnet 範圍中

<br>

每個 Container 都在自己的 Network Namespace 中，各自擁有獨立的network stack。

<br>

Docker 會在 Host 上為每個 Container 建立一對 veth pair：

<br>

內側 (veth-container) 放在 Container 的 eth0
外側 (veth-host) 接回到 Host 的 docker0 bridge

<br>

Host 透過 iptables 自動設置 NAT (MASQUERADE) 規則，讓 Container 可以經由 Host 公網介面對外進行封包轉送。

<br>

### 在 Container 內查看網路介面

執行 docker container exec -it alpine1 ip addr 觀察網路介面

<br>

![alt text](./image-10.png)

<br>

lo：回環介面，IP 為 127.0.0.1/8
eth0：連到 docker0 的 veth，通常 IP 為 172.17.0.X/16

<br>

eth0 是 Container 中唯一的「外部」網路介面，所有對外流量都須先經由此介面到達 Host 的 docker0，再由 Host 轉送或進行 NAT。

<br>

### 在 Host 上查看整體網路結構

![alt text](./image-11.png)

<br>

會藉由 docker0 這個 bridge，讓 container 之間能互相溝通，也讓 container 有了對外部網路進行存取的能力。

<br>

Container 的封包先從 eth0 進入 veth-container，穿過 veth-host 後到達 docker0, 再由 Host 的 iptables NAT 規則將來源 IP 改為 Host 公網 IP，送到外部網路, 回程封包再反方向經過 docker0 → veth → Container eth0