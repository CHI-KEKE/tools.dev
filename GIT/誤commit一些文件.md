情境判斷：先確認有沒有 push 到遠端

git status -sb
git branch -vv

看  git branch -vv  中你目前分支後面有沒有  [upstream/xxx]  標記：

• 沒有標記／尚未 push → 可以安全改寫本地 commit（用下面「未 push」流程）
• 已經 push 過 → 改寫 commit 後需要  force push ，如果是共用分支要先跟其他人確認，避免別人拉到舊版又衝突

情境 A：尚未 push（最單純）

1. 確認錯誤 commit 裡有哪些檔案
git show --stat HEAD
2. 把不該進版控的檔案從 git 索引移除，但保留在硬碟上
git rm --cached "路徑\檔案1" "路徑\檔案2"
•  --cached  是關鍵：只從 Git 追蹤移除，實體檔案不會被刪掉
• 如果檔案很多，也可以用資料夾： git rm --cached -r ".doc" 
3. 把這次移除合併回原本的 commit（不改 commit message）
git commit --amend --no-edit
• 這會產生一個新的 commit hash 取代原本的 commit，內容只剩下真正該有的檔案
4. 驗證結果
git show --stat HEAD
git status
``` 確認誤加的檔案已經不在 commit 裡，且在 `git status` 顯示為 `Untracked files`（代表檔案還在硬碟上）。

情境 B：已經 push 過了

多一個步驟：

1. 同上，先用  git rm --cached  +  git commit --amend --no-edit  修正本地 commit
2. 強制推送覆蓋遠端（因為 commit hash 變了）
git push --force-with-lease
• 建議用  --force-with-lease  而不是  --force ：如果遠端在你 push 之後又被別人更新過，它會拒絕覆蓋，避免不小心蓋掉別人的 commit
• 如果分支是多人協作，push 前務必先跟團隊說一聲

補充：如果誤加的 commit 已經不是最新一筆（中間夾了其他 commit）

用  git rebase -i  找到那筆 commit 改成  edit ，進去後一樣執行  git rm --cached  →  git commit --amend --no-edit  →  git rebase --continue 。這種情況相對複雜，若真的遇到可以再詳細討論。

順手預防

把常誤 commit 的資料夾（例如  .doc/ ）加進  .gitignore ，之後  git add .  或  git add -A  就不會再誤抓進去：

Add-Content .gitignore "`n.doc/"