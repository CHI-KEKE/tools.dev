
## git add


git add charts/live-comment-sync/values-tw-prod.yaml
charts/live-comment-sync/values-hk-prod.yaml
charts/live-comment-sync/values-my-prod.yaml
nine1-devops-deployments.Prod.json


## git commit


git commit -m "feat: add live-comment-sync prod values for TW/HK/MY and
update deployment config


## git push 指定 branch
git push -u upstream feature/VSTS584874-PollingLiveComments-prod


## push HEAD 會自動對應當前 branch 名稱，不需要手動輸入

git push -u upstream HEAD


## commit

`git commit -m "feat(audit): implement Audit Collection Service"`



## commit type

- feat: 新功能
- fix: 修正 bug
- docs :文件內容修改
- style: 跟程式碼語意無關的修改，包含修改縮排、新增分號 … 等等之類的
- refactor: 無關新功能與 bug 修正的程式碼修改
- perf: 程式碼對於提升效能有幫助的修改
- test: 新增或修改測試
- ci: 修改 ci 的配置檔
- chore: 無關 `src`, `test` 路徑內的檔案修改
- revert: 恢復某個提交
- build: 改變打包流程

## 撤回到特定 commit

```bash
##先看git log 紀錄

$ git log --oneline
e12d8ef (HEAD -> master) add database.yml in config folder
85e7e30 add hello
657fce7 add container
abb4f43 update index page
cef6e40 create index page
cc797cd init commit

##「相對」的做法

$ git reset e12d8ef^ (到上一個commit)


##因為剛好 HEAD 跟 master 目前都是指向 e12d8ef 這個 Commit，而且 e12d8ef 這個數字也不好記，所以上面這行，通常也會改寫成

git reset master^
git reset HEAD^


## 你很清楚想要把目前的狀態退回到哪個 Commit，可以直接指明

git reset 85e7e30
```

## Track 本地還沒有的branch

```bash
git checkout -b feature/VSTS345336_MY_QA_New_Cart upstream/feature/VSTS345336_MY_QA_New_Cart
git pull upstream feature/VSTS345336_MY_QA_New_Cart
```


##　Merge without commit

```bash
git merge <name-of-branch> --no-commit
```


## Git砍東西

//git

```bash
git reset -hard
rm -r Recursive
Remove-Item -Path "C:\Path\To\Your\Directory" -Recurse
```


## 到.git file 修正 Branch name




## git branch list (feature/VSTS564624-QA9-CartReachPriceExtraPurchase)



git ls-remote --heads upstream branch名稱




git branch --list "*QA9*"



## rebase


git log --oneline

git rebase -i 099a53a

要拿掉得改成 f 前綴,要留下來的可以改訊息

git push upstream master --force

