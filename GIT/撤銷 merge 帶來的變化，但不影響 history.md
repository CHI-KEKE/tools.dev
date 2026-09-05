## 具體情境

🎭 角色

- 主分支：main
- 功能分支：feature/payment-refactor
- 同事 A：正在基於 main 開發其他功能
- CI/CD：merge 到 main 就自動部署


在 main 上不小心 merge 了一個「還沒準備好」的分支

```bash
git checkout main
git merge feature/payment-refactor
git push origin main
```

CI 開始跑，5 分鐘後 🚨 Production 付款失敗


## ❌ 幹，我 reset 回去就好！

```bash
git reset --hard HEAD~1
git push --force
```

同事 A 本地已經 pull 過 main，歷史被改寫，大家開始出現
```bash
fatal: refusing to merge unrelated histories
rebase 地獄
Slack 開始暴動
```


## 正確判斷

這是一個「已經被分享的 merge commit」

```bash
git log --oneline --graph

## *   a74f4 Merge branch 'feature/payment-refactor' into main
## |\
## | * 9c123 payment refactor WIP
## | * 8b456 remove old payment flow
## * | 1fabc hotfix: typo

```

a74f4 是 merge commit（兩個 parent）

#### 關鍵指令

```bash
git revert -m 1 a74f4
```

a74f4 有兩個 parent

- parent 1：main merge 前的狀態
- parent 2：feature/payment-refactor

-m 1 等於你在說「以 main 當時的狀態為正確世界」，Git 算出：「feature/payment-refactor 被 merge 進來時加了哪些東西」

Git 產生一個新 commit：

- 內容：把那些東西全部反向移除
- 歷史：完全不動


#### 影響

main 現在程式碼 看起來像沒 merge 過，`但歷史是完整的`，同事 A：git pull 完全沒事，CI 再跑一次  Production 恢復正常