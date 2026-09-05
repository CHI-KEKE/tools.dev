using Microsoft.Extensions.Logging;
using Nine1.Sample.Project.Console.NMQv3Worker.Service;
using NSubstitute;
using Xunit;

namespace Nine1.Sample.Project.Console.NMQv3Worker.Tests.Service;

public class RepeatMessageServiceTests
{
    private readonly ILogger<RepeatMessageService> _logger = Substitute.For<ILogger<RepeatMessageService>>();

    public RepeatMessageService SystemUnderTest() { return new RepeatMessageService(_logger); }

    [Theory(DisplayName = "DoJob_data 為任何有效的 string_要將 data pass 給 IRepeatMessageService.Repeat 。")]
    [InlineData("hello")]
    [InlineData("{\"data\":\"hello from json\"}")]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" ")]
    public void Repeat_Test(string data)
    {
        // arrange
        var sut = SystemUnderTest();

        // act
        sut.Repeat(data);

        // assert
        _logger.Received(1).LogInformation("========= Start repeating =========");
        _logger.Received(1).LogInformation(data);
        _logger.Received(1).LogInformation("========= Repeated =========");
    }
}