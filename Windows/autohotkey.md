# AutoHotkey — 本機快捷鍵設定

## 概覽

用 **AutoHotkey v2** 實作「打字觸發」快捷鍵，輸入關鍵字後按 Enter，畫面中央出現 OSD 大字提示並自動用 VS Code 開啟指定專案。

---

## 安裝方式

AutoHotkey **非 Windows 內建**，採用 Portable 版本（不需安裝程式）：

```powershell
# 下載 portable zip 並解壓到 C:\AutoHotkey
$url = "https://www.autohotkey.com/download/ahk-v2.zip"
$out = "$env:TEMP\ahk-v2.zip"
Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
Expand-Archive -Path $out -DestinationPath "C:\AutoHotkey" -Force
```

執行檔路徑：`C:\AutoHotkey\AutoHotkey64.exe`

---

## 腳本位置

```
C:\AutoHotkey\MyHotkeys.ahk
```

---

## 開機自動啟動

在 Windows Startup 資料夾建立捷徑：

```powershell
$startupFolder = [System.Environment]::GetFolderPath("Startup")
$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut("$startupFolder\MyHotkeys.lnk")
$shortcut.TargetPath = "C:\AutoHotkey\AutoHotkey64.exe"
$shortcut.Arguments = '"C:\AutoHotkey\MyHotkeys.ahk"'
$shortcut.Save()
```

---

## 手動啟動 / 重啟

```powershell
# 停止舊的 AHK 行程
$procs = Get-Process | Where-Object { $_.Name -like "*AutoHotkey*" }
foreach ($p in $procs) { Stop-Process -Id $p.Id -Force }

# 重新啟動
Start-Process -FilePath "C:\AutoHotkey\AutoHotkey64.exe" -ArgumentList '"C:\AutoHotkey\MyHotkeys.ahk"'
```

---

## 腳本結構說明

### OSD 效果函式

觸發快捷鍵時，畫面中央出現深色大字視窗，1.2 秒後淡出消失：

```ahk
ShowOSD(label, subtitle := "") {
    static g := ""
    try g.Destroy()

    g := Gui("+AlwaysOnTop -Caption +ToolWindow", "OSD")
    g.BackColor := "0D1117"

    g.SetFont("s64 Bold cFFFFFF", "Consolas")
    g.Add("Text", "xm ym+20 Center w860", label)   ; 白色大字（快捷鍵名稱）

    g.SetFont("s20 c58A6FF", "Consolas")
    g.Add("Text", "xm Center w860", subtitle)       ; 藍色副標題（專案名稱）

    guiW := 900, guiH := 200
    g.Show("x" . (A_ScreenWidth - guiW) // 2 . " y" . (A_ScreenHeight - guiH) // 2 . " w" . guiW . " h" . guiH . " NoActivate")
    WinSetTransparent(240, g)

    SetTimer(FadeOSD.Bind(g), -1200)
}

FadeOSD(g, *) {
    loop 24 {
        try WinSetTransparent(240 - (A_Index * 10), g)
        Sleep(25)
    }
    try g.Destroy()
}
```

### 快捷鍵區塊範本

```ahk
::你的關鍵字::
{
    ShowOSD("你的關鍵字", "顯示在副標題的說明")
    Run '"C:\Program Files\Microsoft VS Code\bin\code.cmd" "C:\你的路徑"',, "Hide"
}
```

> ⚠️ 注意：`Run` 必須用 VS Code 完整路徑 `C:\Program Files\Microsoft VS Code\bin\code.cmd`，
> 不能用 `code`（AHK 不繼承系統 PATH）。

---

## 目前設定的快捷鍵

| 輸入 + Enter | 專案 | 路徑 |
|---|---|---|
| `oppwebapi` | Promotion WebAPI | `C:\91APP\Promotion\webapi\nine1.promotion.web.api` |
| `oppfwebapi` | Promotion Frontend WebAPI | `C:\91APP\Promotion\frontEnd\nine1.promotion.web.api.frontend` |
| `oppengine` | Promotion Engine | `C:\91APP\Promotion\Engine\nineyi.msa.promotion` |
| `opcommerceworker` | Commerce Worker | `C:\91APP\CommerceCloud_NMQV3Worker\nine1.commerce.nmqv3.worker` |
| `opshop` | Shopping | `C:\91APP\Shopping` |
| `opcart` | Cart | `C:\91APP\Cart\cart2\nine1.cart` |
| `ophexo` | Hexo 技術部落格 | `C:\Users\Allen Lin\Desktop\Hexo` |
| `ophexo-en` | Hexo 英文部落格 | `C:\Users\Allen Lin\Desktop\Hexo-en` |
| `ophexo-j` | Hexo 生活體悟 | `C:\Users\Allen Lin\Desktop\Hexo-Journel` |
| `opjoy` | 電商筆記 joy | `C:\Users\Allen Lin\Desktop\joy_2\joy_` |
| `optool` | 工具筆記 tools.dev | `C:\Users\Allen Lin\Desktop\Tool.dev_ingit\tools.dev` |
| `oppics` | Pics 資料夾 (Explorer) | `C:\91APP\AI_Devs\pics\pics` |
| `opaicodereview` | AI Code Review V2 | `C:\91APP\AI_Devs\codereview\NineYi.Ai.Code.Review.V2` |
| `opscmnmq` | SCM NMQ V2 | `C:\91APP\NMQ\nineyi.scm.nmqv2` |
| `opliveapi` | Live Buy API | `C:\91APP\AI_Devs\liveby\nine1.live.buy` |
| `oppworker` | Promotion Worker | `C:\91APP\Promotion\worker\nine1.promotion.worker` |
| `oplinter` | Linter | `C:\91APP\linter` |

---

## 新增快捷鍵流程

1. 編輯 `C:\AutoHotkey\MyHotkeys.ahk`
2. 照範本新增一個區塊
3. 重新啟動 AHK（見上方「手動啟動 / 重啟」）

---

## 注意事項

- AHK 的文字觸發（hotstring）預設用「結束字元」觸發，**Enter / Space / Tab** 都算
- 若不小心輸入到一半想取消，按 **Backspace** 清掉文字即可，不會觸發
- 若 AHK 被手動關閉，快捷鍵會失效，需手動重啟或重開機讓 Startup 捷徑自動執行
