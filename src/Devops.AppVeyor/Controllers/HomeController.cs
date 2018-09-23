using System.Web.Mvc;

namespace Devops.AppVeyor.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return Content("OK");
        }
    }
}