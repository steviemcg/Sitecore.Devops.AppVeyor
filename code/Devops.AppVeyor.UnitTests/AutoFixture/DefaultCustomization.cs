using Ploeh.AutoFixture;
using Ploeh.AutoFixture.AutoNSubstitute;

namespace Devops.AppVeyor.UnitTests.AutoFixture
{
    internal class DefaultCustomization : CompositeCustomization
    {
        public DefaultCustomization()
            : base(
                new AutoNSubstituteCustomization(),
                new MvcCustomization())
        {
        }
    }
}
