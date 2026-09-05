using System;
using System.Collections.Generic;
using FluentAssertions;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using NSubstitute.ReturnsExtensions;
using Xunit;

// ============================================================================
// Template: Service Unit Test Class
// Compatible: .NET Framework 4.8 (xUnit 2.x, NSubstitute 2.x, FluentAssertions 4.x)
//             .NET Core (xUnit 2.x+, NSubstitute 4.x+, FluentAssertions 6.x+)
// ============================================================================

namespace NineYi.WebStore.Frontend.BLV2.Test.Xunit.SomeModule
{
    /// <summary>
    /// SomeService test class
    /// </summary>
    public class SomeServiceTests
    {
        //// Mock dependencies
        private readonly ISomeDependency _someDependency;
        private readonly IAnotherDependency _anotherDependency;
        private readonly ILogger _logger;

        public SomeServiceTests()
        {
            //// Initialize all mock dependencies
            this._someDependency = Substitute.For<ISomeDependency>();
            this._anotherDependency = Substitute.For<IAnotherDependency>();
            this._logger = Substitute.For<ILogger>();
        }

        // -------------------------------------------------------------------------
        // GetSomeData method tests
        // -------------------------------------------------------------------------

        [Fact]
        [Trait("Category", nameof(SomeService.GetSomeData))]
        public void GetSomeData_輸入有效參數_應回傳正確資料()
        {
            // Arrange
            var sut = this.GetSystemUnderTest();

            //// Set dependency return value
            this._someDependency.GetById(Arg.Any<int>())
                .Returns(new SomeEntity { Id = 1, Name = "Test" });

            // Act
            var actual = sut.GetSomeData(shopId: 1, itemId: 1);

            // Assert
            actual.Should().NotBeNull();
            actual.Name.Should().Be("Test");
        }

        [Fact]
        [Trait("Category", nameof(SomeService.GetSomeData))]
        public void GetSomeData_依賴回傳null_應回傳空結果()
        {
            // Arrange
            var sut = this.GetSystemUnderTest();

            //// Set dependency to return null
            this._someDependency.GetById(Arg.Any<int>())
                .ReturnsNull();

            // Act
            var actual = sut.GetSomeData(shopId: 1, itemId: 999);

            // Assert
            actual.Should().BeNull();
        }

        [Fact]
        [Trait("Category", nameof(SomeService.GetSomeData))]
        public void GetSomeData_依賴拋出例外_應拋出對應例外()
        {
            // Arrange
            var sut = this.GetSystemUnderTest();

            //// Set dependency to throw exception
            this._someDependency.GetById(Arg.Any<int>())
                .Throws(new InvalidOperationException("Connection failed"));

            // Act
            Action act = () => sut.GetSomeData(shopId: 1, itemId: 1);

            // Assert
            act.Should().Throw<InvalidOperationException>()
               .WithMessage("*Connection failed*");
        }

        // -------------------------------------------------------------------------
        // ProcessSomeLogic method tests (conditional branches)
        // -------------------------------------------------------------------------

        [Fact]
        [Trait("Category", nameof(SomeService.ProcessSomeLogic))]
        public void ProcessSomeLogic_條件A成立_應執行路徑A()
        {
            // Arrange
            var sut = this.GetSystemUnderTest();

            //// Set condition A to true
            this._someDependency.CheckCondition(Arg.Any<int>())
                .Returns(true);

            // Act
            var actual = sut.ProcessSomeLogic(inputId: 1);

            // Assert
            actual.ResultType.Should().Be("PathA");
            this._anotherDependency.Received(1).ExecutePathA(Arg.Any<int>());
        }

        [Fact]
        [Trait("Category", nameof(SomeService.ProcessSomeLogic))]
        public void ProcessSomeLogic_條件A不成立_應執行路徑B()
        {
            // Arrange
            var sut = this.GetSystemUnderTest();

            //// Set condition A to false
            this._someDependency.CheckCondition(Arg.Any<int>())
                .Returns(false);

            // Act
            var actual = sut.ProcessSomeLogic(inputId: 1);

            // Assert
            actual.ResultType.Should().Be("PathB");
            this._anotherDependency.DidNotReceive().ExecutePathA(Arg.Any<int>());
        }

        // -------------------------------------------------------------------------
        // GetListData method tests (collection return)
        // -------------------------------------------------------------------------

        [Fact]
        [Trait("Category", nameof(SomeService.GetListData))]
        public void GetListData_有資料時_應回傳正確數量()
        {
            // Arrange
            var sut = this.GetSystemUnderTest();

            //// Set dependency to return multiple items
            this._someDependency.GetAll(Arg.Any<int>())
                .Returns(new List<SomeEntity>
                {
                    new SomeEntity { Id = 1, Name = "Item1" },
                    new SomeEntity { Id = 2, Name = "Item2" },
                    new SomeEntity { Id = 3, Name = "Item3" }
                });

            // Act
            var actual = sut.GetListData(shopId: 1);

            // Assert
            actual.Should().NotBeNull();
            actual.Should().HaveCount(3);
            actual.Should().Contain(x => x.Name == "Item1");
        }

        [Fact]
        [Trait("Category", nameof(SomeService.GetListData))]
        public void GetListData_無資料時_應回傳空集合()
        {
            // Arrange
            var sut = this.GetSystemUnderTest();

            //// Set dependency to return empty collection
            this._someDependency.GetAll(Arg.Any<int>())
                .Returns(new List<SomeEntity>());

            // Act
            var actual = sut.GetListData(shopId: 1);

            // Assert
            actual.Should().NotBeNull();
            actual.Should().BeEmpty();
        }

        // -------------------------------------------------------------------------
        // Theory parameterized test example
        // -------------------------------------------------------------------------

        [Theory]
        [Trait("Category", nameof(SomeService.CalculateDiscount))]
        [InlineData(100, 10, 90)]
        [InlineData(200, 20, 160)]
        [InlineData(0, 10, 0)]
        public void CalculateDiscount_輸入各種金額與折扣_應回傳正確結果(
            decimal amount, decimal discountPercent, decimal expected)
        {
            // Arrange
            var sut = this.GetSystemUnderTest();

            // Act
            var actual = sut.CalculateDiscount(amount, discountPercent);

            // Assert
            actual.Should().Be(expected);
        }

        // -------------------------------------------------------------------------
        // SUT creation helper
        // -------------------------------------------------------------------------

        /// <summary>
        /// Create System Under Test instance (SUT)
        /// </summary>
        private SomeService GetSystemUnderTest()
        {
            return new SomeService(
                this._someDependency,
                this._anotherDependency,
                this._logger);
        }
    }
}
