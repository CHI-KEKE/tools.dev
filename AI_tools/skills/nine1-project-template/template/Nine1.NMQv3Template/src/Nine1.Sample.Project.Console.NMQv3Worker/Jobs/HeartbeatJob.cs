using System.Threading;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Nine1.Sample.Project.Console.NMQv3Worker.DI;
using Nine1.NMQ.Extensions.Hosting.Contracts;

namespace Nine1.Sample.Project.Console.NMQv3Worker.Job;

[HeartbeatJobDI]
public class HeartbeatJob : IProcess
{
    private readonly ILogger<HeartbeatJob> _logger;
    private readonly IConfiguration _configuration;

    public HeartbeatJob(ILogger<HeartbeatJob> logger, IConfiguration configuration)
    {
        this._logger = logger;
        this._configuration = configuration;
    }

    public void Dispose() { }

    public void DoJob(string data, CancellationToken cancellationToken)
    {
        _logger.LogInformation($"_N1CONFIG:TestKey: [{_configuration["_N1CONFIG:TestKey"]}]");
        _logger.LogInformation($"N1_MARKET: [{_configuration["N1_MARKET"]}]");
        _logger.LogInformation($"N1_ENVIRONMENT: [{_configuration["N1_ENVIRONMENT"]}]");
        _logger.LogInformation("OK");
    }
}