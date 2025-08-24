# Visual Studio 指南

## 目錄
- [快捷鍵](#快捷鍵)
- [Show Files 找不到問題](#show-files-找不到問題)
- [Build 卡死](#build-卡死)
- [Show All Files](#show-all-files)
- [Load / Unload Project](#load--unload-project)
- [語言設定](#語言設定)

<br><br>

---

## 快捷鍵

| 功能 | 快捷鍵 |
|------|-------|
| 註解 | Ctrl + K, Ctrl + C |
| 取消註解 | Ctrl + K, Ctrl + U |
| 摺疊 | Ctrl + M |
| 除錯模式 | F5 |
| 重新命名 | Ctrl + R |
| 例外類別產生 | Exception + Tab |
| 自動產生迴圈 | for + Tab + Tab |
| 檔案切換 | Ctrl + Tab |
| 定義 | F12 |
| 返回 | Ctrl + - |
| 前進 | Ctrl + Shift + - |

<br><br>

---

## Show Files 找不到問題

當資料夾有檔案但 show files 找不到時，需要手動將專案加入 VS。

<br>

### 解決步驟

1. 右鍵點選 Solution
2. 選擇 Add
3. 選擇 Add Existing Projects

<br><br>

---

## Build 卡死

Build 卡死有時候是觸發不了登入機制，需要登入公司網站。

<br>

### 解決方法

確認已登入公司網站並重新嘗試建構。

<br><br>

---

## Show All Files

![alt text](./image.png)

<br>

Show all files 功能可以顯示所有檔案（範例如用 custom tools 抓下來的檔案可能 VS IDE 認不得，要把它加進來）。

<br><br>

---

## Load / Unload Project

### 什麼是 Load / Unload Project？

在 Visual Studio 中，Load（載入）/ Unload（卸載）Project 是用來暫時啟用或停用某個專案（Project）的功能。

<br>

**Load Project** → 將專案載入 Solution，參與編譯、執行與 IntelliSense

<br>

**Unload Project** → 將專案從 Solution 暫時卸載，不參與編譯，節省資源

<br>

### 什麼時候該用 Unload Project？

以下是最常見的 4 大情境：

<br>

**加速 Visual Studio 開啟速度**

<br>

使用時機：大型 Solution 中有很多專案，但你只需要其中一部分時

<br>

好處：減少記憶體占用與載入時間，編輯或除錯時效能更好

<br>

**避免影響其他專案**

<br>

使用時機：A 專案依賴 B 專案，但你目前只要維護 A

<br>

好處：Unload B 可以避免因為 B 的編譯失敗或相依性改動導致額外錯誤

<br>

**切換不同版本的專案**

<br>

使用時機：需要在同一個 Solution 裡測試多組組合，例如：

<br>

- ProjectA (Debug) + ProjectB (Release)
- ProjectA (Debug) + ProjectC (Debug)

<br>

好處：卸載不需要的版本，避免重複載入相同相依元件造成衝突

<br>

**編輯專案檔（.csproj）**

<br>

使用時機：需要手動編輯 *.csproj 設定（範例如變更 Build 設定、條件式相依）

<br>

操作流程：

<br>

1. 在 Solution Explorer 中右鍵點專案 → Unload Project
2. 再次右鍵 → Edit {ProjectName}.csproj
3. 編輯完成後儲存並關閉
4. 右鍵 → Reload Project

<br>

### Load / Unload Project 操作方法

| 操作 | 說明 |
|------|------|
| Unload Project | Solution Explorer → 右鍵專案 → Unload Project |
| Reload Project | 卸載後 → 右鍵專案（顯示為灰色）→ Reload Project |
| 編輯專案檔 | 卸載後 → 右鍵 → Edit .csproj |

<br><br>

---

## 語言設定

若沒有想要的語言，先關閉視窗。點選 **工具 / 取得工具與功能 (Tools/Get Tools and Features)**，開啟安裝程式。

<br>

選擇**語言套件 (Language Packs)**，勾選要安裝語言，點選右下角**修改 (Modify)** 按鈕。

<br>

![alt text](./image-1.png)

<br>

![alt text](./image-2.png)

<br>

![alt text](./image-3.png)