using Microsoft.Extensions.Logging;
using Nine1.Sample.Project.Console.NMQv3Worker.Contract;
using Nine1.Sample.Project.Console.NMQv3Worker.Job;
using NSubstitute;
using Xunit;

namespace Nine1.Sample.Project.Console.NMQv3Worker.Tests.Job;

public class RepeatMessageJobTests
{
    private readonly ILogger<RepeatMessageJob> _logger = Substitute.For<ILogger<RepeatMessageJob>>();
    private readonly IRepeatMessageService _repeatMessageService = Substitute.For<IRepeatMessageService>();

    public RepeatMessageJob SystemUnderTest() { return new RepeatMessageJob(_logger, _repeatMessageService); }

    [Theory(DisplayName = "DoJob_data 為任何有效的 string_要將 data pass 給 IRepeatMessageService.Repeat 。")]
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
        _repeatMessageService.Received(1).Repeat(data);
    }
}