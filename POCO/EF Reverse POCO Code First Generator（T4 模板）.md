工具說明

  這個專案用的是 Visual Studio 的 T4 Text Template（.tt 檔） 搭配 EF Reverse POCO Code First Generator 這個 NuGet 工具（版本 v2.17.2）。

  運作方式

   1. 每個 DB 對應一個 .tt 檔（例如 AuthExternalDB.tt）
   2. 只要在 Visual Studio 中「儲存」這個 .tt 檔，T4 引擎就會自動連線 DB，掃描所有表格結構，重新產生對應的 .cs 檔
   3. 不需要 Build，儲存即產生




##  實戰步驟


✅ 步驟 1（已完成）：修改 AuthExternalDB.tt

  TableFilterInclude 已更新，加入了 SystemModule 和 SystemFunction。

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  步驟 2：在 Visual Studio 執行 T4

  在 Visual Studio 中：

   1. Solution Explorer 展開 DataAccess\AuthExternalDB\Tables\
   2. 右鍵點擊 AuthExternalDB.tt
   3. 選擇 「Run Custom Tool」（或直接按 Ctrl+S 儲存此檔）

  執行後應看到 Tables/ 下新增了 4 個檔案：

   Tables/
     SystemModule.cs                  ← 新增
     SystemModuleConfiguration.cs     ← 新增
     SystemFunction.cs                ← 新增
     SystemFunctionConfiguration.cs   ← 新增

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  步驟 3：確認 .csproj 是否自動加入

  T4 有時不會自動更新 .csproj（classic format 不像 SDK-style 會自動掃描）。請打開：

   DataAccess\AuthExternalDB\NineYi.Scm.ApiV2.DA.AuthExternalDB.csproj

  確認是否有這 4 筆 <Compile> 項目。如果沒有，手動加入（加在 UsersConfiguration.cs 那行的下方）：
● Edit SCMAPIV2\nineyi.scm.apiv2\DataAccess\AuthExternalDB\NineYi.Scm.ApiV2.DA.AuthExternalDB.csproj (+12)

● .csproj 已預先加入 4 個新項目，無論 T4 是否自動更新都不影響。

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  步驟 4：T4 跑完後驗證 AuthExternalDbContext.cs 和 IAuthExternalDbContext.cs

  T4 會自動覆寫這兩個檔案（它們是 auto-generated）。確認以下內容是否出現：

  AuthExternalDbContext.cs 應多出：

   public DbSet<SystemModule> SystemModule { get; set; }
   public DbSet<SystemFunction> SystemFunction { get; set; }

  以及 OnModelCreating 中：

   modelBuilder.Configurations.Add(new SystemModuleConfiguration());
   modelBuilder.Configurations.Add(new SystemFunctionConfiguration());

  IAuthExternalDbContext.cs 應多出：

   DbSet<SystemModule> SystemModule { get; set; }
   DbSet<SystemFunction> SystemFunction { get; set; }

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  步驟 5：Build 確認無錯誤

   Build → Build Solution（Ctrl+Shift+B）

  應看到 NineYi.Scm.ApiV2.DA.AuthExternalDB 成功編譯。

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  執行順序摘要

  ┌───┬────────────────────────────────────────────────────────────────────┬───────────────────────────────────────────┬──────────┐
  │ # │ 動作                                                               │ 位置                                      │ 由誰執行 │
  ├───┼────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────┼──────────┤
  │ 1 │ ✅ 修改 TableFilterInclude 加入兩張表                              │ AuthExternalDB.tt L117-121                │ 已完成   │
  ├───┼────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────┼──────────┤
  │ 2 │ 在 VS 右鍵 AuthExternalDB.tt → Run Custom Tool                     │ Visual Studio                             │ 你操作   │
  ├───┼────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────┼──────────┤
  │ 3 │ T4 自動產生 4 個 .cs 檔                                            │ Tables/ 資料夾                            │ 自動     │
  ├───┼────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────┼──────────┤
  │ 4 │ ✅ .csproj 加入 4 筆 <Compile>                                     │ NineYi.Scm.ApiV2.DA.AuthExternalDB.csproj │ 已完成   │
  ├───┼────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────┼──────────┤
  │ 5 │ 確認 AuthExternalDbContext.cs / IAuthExternalDbContext.cs 有 DbSet │ 自動覆寫                                  │ 目視確認 │
  ├───┼────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────┼──────────┤
  │ 6 │ Build 確認                                                         │ VS                                        │ 你操作   │
  └───┴────────────────────────────────────────────────────────────────────┴───────────────────────────────────────────┴──────────┘



## 為什麼需要 XxxConfiguration.cs？


