using Microsoft.Extensions.DependencyInjection;
using Nine1.Sample.Project.Console.NMQv3Worker.Contract;
using Nine1.Sample.Project.Console.NMQv3Worker.Service;
using Nine1.NMQ.Extensions.Hosting.Attributes;

namespace Nine1.Sample.Project.Console.NMQv3Worker.DI;

public class RepeatMessageJobDIAttribute : DependencyInjectionSettingAttribute
{
    public override void Register(IServiceCollection services)
    {
        services.AddSingleton(typeof(IRepeatMessageService), typeof(RepeatMessageService));
    }
}