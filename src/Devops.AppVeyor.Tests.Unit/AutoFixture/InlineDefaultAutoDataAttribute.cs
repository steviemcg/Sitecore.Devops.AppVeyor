using Ploeh.AutoFixture.Xunit2;

namespace Devops.AppVeyor.Tests.Unit.AutoFixture
{
    public class InlineDefaultAutoDataAttribute : InlineAutoDataAttribute
    {
        public InlineDefaultAutoDataAttribute(params object[] values)
            : base(new DefaultAutoDataAttribute(), values)
        {
        }
    }
}
