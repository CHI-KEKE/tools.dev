
## Git Error - 'lint-staged' is not recognized as an internal or external command

Husky pre-commit hook 有執行 lint-staged

但在你的電腦環境中
→ lint-staged 找不到可執行檔
→ Node 模組沒有裝好、或根本沒有安裝、或 PATH **不對**

<br>

#### ✅ 解決方式 A（最常見）：直接安裝 lint-staged

專案根目錄執行 `npm install --save-dev lint-staged`
裝完重新 commit `git commit`

<br>

---

## Git Error - hexo deploy 出現 `Cannot prompt because user interactivity has been disabled`

#### 錯誤訊息

```
fatal: Cannot prompt because user interactivity has been disabled.
fatal: unable to get password from user
FATAL Something's wrong...
Error: Spawn failed
[ERROR] hexo deploy failed.
```

#### 前因後果

1. **HTTPS 部署需要認證**
   `_config.yml` 的 deploy repo 原本設定成 HTTPS 網址：
   ```
   repo: https://github.com/CHI-KEKE/journal.git
   ```
   用 HTTPS 跟 GitHub 溝通時，git push 需要證明「你是誰」，正常情況會跳出 Windows 的 Git Credential Manager 視窗，讓你登入 / 用瀏覽器授權一次，之後把 token 快取起來。

2. **但這次沒有快取的憑證**
   `.deploy_git`（hexo 部署用的暫存 repo）針對這個 HTTPS 網址從沒有成功登入、快取過 token，所以這次 push 必須「跳出視窗問你」。

3. **但當前環境把「互動提示」關掉了**
   終端機環境變數中有：
   - `GIT_TERMINAL_PROMPT=0`
   - `credential.interactive=never`

   意思是「禁止任何互動式提示（不准跳窗、不准在終端機問密碼）」，這通常是自動化 / 腳本 / AI 代理環境刻意設的安全機制，避免程式卡住等一個不會出現的使用者輸入。

4. **兩者相撞 → 報錯**
   git 想跳窗問登入 → 規則說「不准跳窗」→ git 放棄，丟出上面的錯誤。

#### ✅ 解決方式：改用 SSH 部署，避開整個憑證提示流程

先確認本機 SSH key 已跟 GitHub 配對成功：

```
ssh -T git@github.com
```

若回覆 `Hi <username>! You've successfully authenticated...` 代表 SSH 已可用。

接著把 `_config.yml` 的 deploy repo 改成 SSH 網址：

```yaml
deploy:
  type: git
  repo: git@github.com:CHI-KEKE/journal.git
  branch: master
```

SSH 認證靠的是已配對好的金鑰簽章驗證身份，推送時完全不需要「問密碼」這個互動步驟，因此不會再觸發「禁止互動提示」的規則。改完後重新執行 `hexo deploy` 即可正常推送成功。