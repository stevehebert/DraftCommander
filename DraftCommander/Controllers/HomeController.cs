using System.Web.Mvc;
using DraftCommander.Models;

namespace DraftCommander.Controllers
{
    public class HomeController : Controller
    {
        private readonly InitializationModel _initializationModel;

        public HomeController(InitializationModel initializationModel)
        {
            _initializationModel = initializationModel;
        }


        public ActionResult Index()
        {
            var count = 5;

            ViewBag.Message = string.Format("Welcome to ASP.NET MVC! with {0} players", count);

            return View();
        }

        public ActionResult About()
        {
            return View();
        }

        public JsonResult GridData(string sidx, string sord, int page, int rows)
        {
            return _initializationModel.GetData(Json);
        }
    }
}
