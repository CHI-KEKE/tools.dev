---
name: view-screenshot
description: 當 Allen 說「看截圖」、「看圖」、「請看圖」、「看一下截圖」，或提供任何截圖檔名（如 JJ.png、ss.png、test.jpg 等），立刻到 C:\91APP\AI_Devs\pic-temp\ 目錄下找對應檔案並讀取顯示。不需要等 Allen 給完整路徑。
---

# View Screenshot

## 規則

當 Allen 提到截圖或圖片檔名時，直接用 view 工具讀取：

```
C:\91APP\AI_Devs\pic-temp\<Allen提供的檔名>
```

## 範例

- Allen 說「看截圖 JJ.png」→ 讀取 `C:\91APP\AI_Devs\pic-temp\JJ.png`
- Allen 說「看一下 ss.png」→ 讀取 `C:\91APP\AI_Devs\pic-temp\ss.png`
- Allen 說「請看截圖」但沒給檔名 → 列出目錄內所有檔案，讓 Allen 選擇

## 列出目錄

若 Allen 沒給檔名，用 glob 列出目前有哪些圖：

```
C:\91APP\AI_Devs\pic-temp\*.png
C:\91APP\AI_Devs\pic-temp\*.jpg
```
