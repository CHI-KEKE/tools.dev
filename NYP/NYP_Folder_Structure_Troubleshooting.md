## 核心原理：兩個不同的路徑規則

NYP pipeline 裡有**兩個不同的元件**，各自對資料夾有不同的期待：

| 元件 | 期待的路徑 | 對應錯誤 |
|------|-----------|---------|
| NYP Build Script | `src/{MODULE}/{FQDN}/` | E105 |
| Dockerfile | `src/{FQDN}.sln`（在 src/ 根目錄） | E106 |

這兩個規則**並不矛盾**，但一開始很容易誤以為「MODULE 子資料夾應該影響全部」。

---

## 錯誤一：E105 — 找不到專案路徑

### 錯誤訊息
```
Path: [/builds/.../src/Web/NineYi.Ai.CodeReview.Api] DOES NOT exists.
Return Code: [E105]
```

### 原因

NYP build script 在執行時，會根據 `.gitlab-ci.yml` 的設定組出一個路徑：

```bash
# 當 GLCI__NYS_MODULE 不為空時
./build.sh -f ${FQDN} -m ${MODULE}
# → 去找 src/{MODULE}/{FQDN}/ 資料夾
```

我們設定了 `GLCI__NYS_MODULE: "Web"`，但資料夾結構是：
```
src/
  NineYi.Ai.CodeReview.Api/   ← 沒有 Web/ 這一層
```

### 修法

把所有專案資料夾搬到 `src/Web/` 底下：

```
src/
  Web/
    NineYi.Ai.CodeReview.Api/       ✅ NYP 找得到了
    NineYi.Ai.CodeReview.Application/
    NineYi.Ai.CodeReview.Domain/
    ...
```

---

## 錯誤二：E106 — Dockerfile 找不到 .sln

### 錯誤訊息
```
MSBUILD : error MSB1009: Project file does not exist.
Switch: ./NineYi.Ai.CodeReview.Api.sln
Return Code: [E106]
```

### 原因

Dockerfile 的邏輯是：

```dockerfile
WORKDIR /src
COPY ./src .                          # 把 src/ 整包複製進去
RUN dotnet restore ./${NYS_FQDN}.sln  # 直接在 /src/ 找 .sln
```

我們把 `.sln` 也一起搬進 `src/Web/` 了，所以 Dockerfile 在 `/src/` 根目錄找不到它。

### 修法

`.sln` 必須留在 `src/` **根目錄**，不跟著 MODULE 子資料夾走：

```
src/
  NineYi.Ai.CodeReview.Api.sln   ✅ Dockerfile 在 /src/ 找得到
  Web/
    NineYi.Ai.CodeReview.Api/
    ...
```

---

## 錯誤三：E106 — .sln 內部路徑錯誤

### 錯誤訊息
```
error MSB3202: The project file "/src/NineYi.Ai.CodeReview.Api/NineYi.Ai.CodeReview.Api.csproj" was not found.
Return Code: [E106]
```

### 原因

`.sln` 檔案回到了 `src/` 根目錄，但裡面的 project 參考路徑還是舊的，沒有包含 `Web\` 前綴：

```
# .sln 內舊路徑（錯誤）
"NineYi.Ai.CodeReview.Api\NineYi.Ai.CodeReview.Api.csproj"

# .csproj 實際位置
src/Web/NineYi.Ai.CodeReview.Api/NineYi.Ai.CodeReview.Api.csproj
    ↑
    少了這一層
```

### 修法

更新 `.sln` 內所有 project 的相對路徑，加上 `Web\` 前綴：

```
# 修正後
"Web\NineYi.Ai.CodeReview.Api\NineYi.Ai.CodeReview.Api.csproj"  ✅
```

---

## 最終正確結構

```
repo-root/
├── .gitlab-ci.yml                        ← GLCI__NYS_MODULE: "Web"
├── src/
│   ├── NineYi.Ai.CodeReview.Api.sln      ← 留在 src/ 根（給 Dockerfile 用）
│   └── Web/                              ← MODULE 子資料夾（給 NYP build script 用）
│       ├── NineYi.Ai.CodeReview.Api/     ← 含 .manifest/
│       ├── NineYi.Ai.CodeReview.Application/
│       ├── NineYi.Ai.CodeReview.Domain/
│       ├── NineYi.Ai.CodeReview.Infrastructure/
│       └── NineYi.Ai.CodeReview.Web/
```

---

## 一句話總結

> **NYP Build Script 要 `src/{MODULE}/{FQDN}/`，Dockerfile 要 `src/{FQDN}.sln`。**
> `.sln` 住在 `src/` 根，專案資料夾住在 `src/{MODULE}/` 裡，`.sln` 內部路徑加 `{MODULE}\` 前綴。

---

## 查錯速查表

| 遇到的錯誤 | 先檢查什麼 |
|-----------|-----------|
| E105 | `src/{MODULE}/{FQDN}/` 資料夾是否存在 |
| E106（sln not found） | `.sln` 是否在 `src/` 根目錄 |
| E106（csproj not found） | `.sln` 內部路徑是否含 `{MODULE}\` 前綴 |
