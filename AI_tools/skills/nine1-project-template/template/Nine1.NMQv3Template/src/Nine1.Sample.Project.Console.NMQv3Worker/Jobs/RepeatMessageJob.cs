using System.Threading;
using Microsoft.Extensions.Logging;
using Nine1.Sample.Project.Console.NMQv3Worker.Contract;
using Nine1.Sample.Project.Console.NMQv3Worker.DI;
using Nine1.NMQ.Extensions.Hosting.Contracts;

namespace Nine1.Sample.Project.Console.NMQv3Worker.Job;

[RepeatMessageJobDI]
public class RepeatMessageJob : IProcess
{
    private readonly ILogger<RepeatMessageJob> _logger;
    private readonly IRepeatMessageService _repeatMessageService;

    public RepeatMessageJob(
        ILogger<RepeatMessageJob> logger,
        IRepeatMessageService repeatMessageService
    )
    {
        this._logger = logger;
        this._repeatMessageService = repeatMessageService;
    }

    public void Dispose() { }

    public void DoJob(string data, CancellationToken cancellationToken) { _repeatMessageService.Repeat(data); }
}