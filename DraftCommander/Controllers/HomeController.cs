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

        public JsonResult GridData(string sidx, string sord, int page, int rows)
        {
            return _initializationModel.GetData(Json);
        }

        public JsonResult OwnerData(string idx, string sord, int page, int rows)
        {
            return _initializationModel.GetOwnerData(Json);
        }

        public JsonResult BidDetail(int auctionId)
        {
            Thread.Sleep(500);
            return _initializationModel.GetBidData(auctionId, o => Json(o, JsonRequestBehavior.AllowGet));
        }

        public JsonResult AuctionRules(int auctionId)
        {
            return _initializationModel.GetAuctionRules(auctionId, o => Json(o, JsonRequestBehavior.AllowGet));
        }
    }
}
