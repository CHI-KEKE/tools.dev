# Docker 概念

## 目錄
- [Image Layer](#image-layer)

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