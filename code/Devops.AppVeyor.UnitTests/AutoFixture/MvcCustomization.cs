using System.Web.Mvc;
using Ploeh.AutoFixture;

namespace Devops.AppVeyor.UnitTests.AutoFixture
{
    internal class MvcCustomization : ICustomization
    {
        public void Customize(IFixture fixture)
        {
            fixture.Customize<ControllerContext>(c => c.OmitAutoProperties());
        }
    }
}