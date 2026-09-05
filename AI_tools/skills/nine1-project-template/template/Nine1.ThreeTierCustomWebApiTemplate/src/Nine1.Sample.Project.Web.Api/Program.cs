using Nine1.Sample.Project.BL.Services.Announcements;
using Nine1.Sample.Project.DA.Repositories.Announcements;
using Nine1.Sample.Project.Web.Api.Extension;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Host.InitNine1BaseSDK(args);

builder.Services.AddControllers();
builder.Services.AddHealthChecks()
    // "self" check 代表服務本身存活，供 /_hc liveness probe 使用，通常不需修改。
    .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy());
    // TODO: 若需要 startup probe 檢查（如 DB 連線），請繼續串接 .AddCheck / .AddNpgSql / .AddSqlServer 等，
    //       並加上 tags: new[] { "startup" }，例如：
    //       .AddNpgSql(Configuration.GetConnectionString("Default")!, name: "db", tags: new[] { "startup" });

#if(isDatabaseSecretPostgresql)
// 加入 Nine1 Secret Connection String Provider
builder.Services.AddNine1SecretConnectionStringProvider<Npgsql.NpgsqlConnectionStringBuilder>();
#endif
#if(isDatabaseSecretMssql)
// 加入 Nine1 Secret Connection String Provider
builder.Services.AddNine1SecretConnectionStringProvider<Microsoft.Data.SqlClient.SqlConnectionStringBuilder>();
#endif

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();

// Optional: 加入 Swagger 初始化設定
builder.Services.AddNine1SwaggerGenerator();

builder.Services.AddScoped<IAnnouncementService, AnnouncementService>();
builder.Services.AddScoped<IAnnouncementRepository, AnnouncementRepository>();

var app = builder.Build();

// 新增 Nine1 Web Extension
app.UseNine1BaseSDKWebExtension();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseCors(
        options => options.SetIsOriginAllowed(x => _ = true).AllowAnyMethod().AllowAnyHeader().AllowCredentials()
    );
    app.UseOpenApi();
    app.UseSwaggerUi();
}

//// Api Exception Handler (這邊設定一個共用的 Exception Handle)
//app.UseGlobalExceptionHandle("/api");

// /_hc：liveness probe，篩選名稱含 "self" 的 check，確認服務本身存活。
app.UseHealthChecks(
    "/_hc",
    new HealthCheckOptions
    {
        Predicate = registration => registration.Name.Contains("self")
    });

// /_hc/startup：startup probe，篩選帶有 "startup" tag 的 check，供 Kubernetes startupProbe 使用。
// TODO: 請在 AddHealthChecks() 串接具體的 check 並加上 tags: new[] { "startup" }，
//       例如：.AddNpgSql(..., tags: new[] { "startup" })
//       若無帶 "startup" tag 的 check，此 endpoint 預設回傳 200 Healthy（放行）。
app.UseHealthChecks(
    "/_hc/startup",
    new HealthCheckOptions
    {
        Predicate = registration => registration.Tags.Contains("startup")
    });

app.UseAuthorization();
app.MapControllers();

app.Run();
