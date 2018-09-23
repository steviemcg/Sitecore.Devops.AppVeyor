using System.Web.Mvc;
using Ploeh.AutoFixture;

namespace Devops.AppVeyor.Tests.Unit.AutoFixture
{
    internal class MvcCustomization : ICustomization
    {
        public void Customize(IFixture fixture)
        {
            fixture.Customize<ControllerContext>(c => c.OmitAutoProperties());
        }
    }
}