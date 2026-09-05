using Microsoft.Extensions.DependencyInjection.Extensions;
using Nine1.BaseSDK;
using NSwag;

namespace Nine1.Sample.Project.Web.Api.Extension;

public static class SwaggerExtension
{
    /// <summary>
    /// 註冊 Swagger 設定到 DI 容器中
    /// </summary>
    /// <param name="services">IServiceCollection</param>
    /// <returns>IServiceCollection</returns>
    public static IServiceCollection AddNine1SwaggerGenerator(this IServiceCollection services)
    {
        services.AddOpenApiDocument((config, sp) =>
        {
            var releng = sp.GetRequiredService<INine1Context>().Releng;

            config.DocumentName = "v" + releng.Versioning.Split(".")[0];
            config.Title = "Nine1.Sample.Project";
            config.Version = releng.Versioning;
            config.Description = "WebAPI of Nine1.Sample.Project";
            config.PostProcess = (doc) =>
            {
                doc.Info.TermsOfService = "http://www.91dev.tw/nineyi.portal/";
                doc.Info.Contact = new OpenApiContact
                {
                    Name = "UPD Arch Team",
                    Email = "upd.arch@91app.com",
                    Url = "http://www.91dev.tw/nineyi.portal/"
                };

                doc.ExternalDocumentation = new OpenApiExternalDocumentation
                {
                    Description = "Doc - Error code",
                    Url = "http://www.91dev.tw/nineyi.portal/"
                };
            };
        });

        return services;
    }
}