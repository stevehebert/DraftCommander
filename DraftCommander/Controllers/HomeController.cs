using System.Threading;
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


        public JsonResult AuctionBigGulp(int auctionId)
        {
            return _initializationModel.BigGulp(auctionId, o => Json(o, JsonRequestBehavior.AllowGet));
        }

        public ActionResult Index()
        {
            var count = 5;

            ViewBag.Message = string.Format("Welcome to DraftCommander with {0} players", count);

            return View(_initializationModel);
        }

        public ActionResult About()
        {
            return View();
        }


    }
}
