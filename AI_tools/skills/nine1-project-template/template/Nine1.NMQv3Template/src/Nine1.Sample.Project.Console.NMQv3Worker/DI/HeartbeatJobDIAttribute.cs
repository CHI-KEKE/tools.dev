using Microsoft.Extensions.DependencyInjection;
using Nine1.NMQ.Extensions.Hosting.Attributes;

namespace Nine1.Sample.Project.Console.NMQv3Worker.DI;

public class HeartbeatJobDIAttribute : DependencyInjectionSettingAttribute
{
    public override void Register(IServiceCollection services) { }
}