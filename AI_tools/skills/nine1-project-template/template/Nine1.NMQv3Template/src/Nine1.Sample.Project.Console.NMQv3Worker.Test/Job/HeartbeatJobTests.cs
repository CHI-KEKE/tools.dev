using System.Collections.Generic;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Nine1.Sample.Project.Console.NMQv3Worker.Job;
using NSubstitute;
using Xunit;

namespace Nine1.Sample.Project.Console.NMQv3Worker.Tests.Job;

public class HeartbeatJobTests
{
    private ILogger<HeartbeatJob> _logger = Substitute.For<ILogger<HeartbeatJob>>();
    private IConfiguration _configuration;

    public HeartbeatJob SystemUnderTest()
    {
        var inMemorySettings = new Dictionary<string, string>
        {
            { "_N1CONFIG:TestKey", "TestValue" },
            { "N1_MARKET", "fake market" },
            { "N1_ENVRIONMENT", "fake environment" },
        };

        _configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings)
            .Build();

        return new HeartbeatJob(_logger, _configuration);
    }

    [Theory(DisplayName = "DoJob_data 為任何有效的 string_要呼叫 ILogger 印出 log ，且 log level 為 info 、 message 為 \"OK\" 。")]
    [InlineData("hello")]
    [InlineData("{\"data\":\"hello from json\"}")]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" ")]
    public void DoJob_Test(string data)
    {
        // arrange
        var sut = SystemUnderTest();

        // act
        sut.DoJob(data, default);

        // assert
        _logger.Received(1).LogInformation("OK");
    }
}