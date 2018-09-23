using Ploeh.AutoFixture;
using Ploeh.AutoFixture.Xunit2;

namespace Devops.AppVeyor.Tests.Unit.AutoFixture
{
    public class DefaultAutoDataAttribute : AutoDataAttribute
    {
        public DefaultAutoDataAttribute()
            : base(new Fixture().Customize(new DefaultCustomization()))
        {
        }
    }
}
