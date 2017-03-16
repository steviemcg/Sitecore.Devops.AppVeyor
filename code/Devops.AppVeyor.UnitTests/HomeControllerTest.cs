using System.Web.Mvc;
using Devops.AppVeyor.Controllers;
using Devops.AppVeyor.UnitTests.AutoFixture;
using Xunit;

namespace Devops.AppVeyor.UnitTests
{
    public class HomeControllerTest
    {
        [Theory]
        [DefaultAutoData]
        public void Index_ReturnsOk(HomeController sut)
        {
            ActionResult result = sut.Index();

            Assert.IsType<ContentResult>(result);
            Assert.Equal("OK", ((ContentResult)result).Content);
        }
    }
}
