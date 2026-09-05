using Microsoft.Extensions.Logging;
using Nine1.Sample.Project.Console.NMQv3Worker.Contract;

namespace Nine1.Sample.Project.Console.NMQv3Worker.Service;

public class RepeatMessageService : IRepeatMessageService
{
    private readonly ILogger<RepeatMessageService> _logger;

    public RepeatMessageService(ILogger<RepeatMessageService> logger) { this._logger = logger; }

    public void Repeat(string message)
    {
        _logger.LogInformation("========= Start repeating =========");
        _logger.LogInformation(message);
        _logger.LogInformation("========= Repeated =========");
    }
}