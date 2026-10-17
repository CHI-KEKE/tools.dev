## 3. Takeover Doctor 是否只是比對 Migration Unit 與 Local？

基本上是，但更精確地說：

> Takeover Doctor 負責確認「這份 Migration Unit 記載的專案」，能不能正確綁定到你電腦上的 Repository。

Migration Unit 裡的 Context 記錄的是共用、可攜帶的資訊，例如：

Legacy 官方 Remote URL
Legacy branch
Legacy baseline commit
Legacy project 相對路徑

Target 官方 Remote URL
Target branch
Target baseline commit
Target project 相對路徑


- 你選到自己的 Fork，但以為是官方 Repository
  - Legacy 還停在舊 commit
  - Target 已經更新，但 Migration Unit 還記錄舊基準
  - 路徑指到另一份同名 Repository
  - Project path 指到錯誤的 .sln 或 .csproj
  - 換了一台電腦，沿用別人的絕對路徑



Takeover Doctor 可以理解成「接手 Migration Unit 前的身分核對員」。

  它主要回答：

  > 你電腦上的 Legacy／Target，真的是這本 Migration Unit 所描述的兩個專案嗎？