using Ploeh.AutoFixture.Xunit2;

namespace Devops.AppVeyor.UnitTests.AutoFixture
{
    public class InlineDefaultAutoDataAttribute : InlineAutoDataAttribute
    {
        public InlineDefaultAutoDataAttribute(params object[] values)
            : base(new DefaultAutoDataAttribute(), values)
        {
        }
    }
}
