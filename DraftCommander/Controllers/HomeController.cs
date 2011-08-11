using System.Web.Mvc;
using MongoDB.Driver;
using Resources;

namespace DraftCommander.Controllers
{
    public class HomeController : Controller
    {
        private IStore<Player> _playerCollection;

        public HomeController(IStore<Player> playerCollection)
        {
            _playerCollection = playerCollection;
        }


        public ActionResult Index()
        {
            var count = _playerCollection.FindAll().Count();

            ViewBag.Message = string.Format("Welcome to ASP.NET MVC! with {0} players", count);

            return View();
        }

        public ActionResult About()
        {
            return View();
        }
    }
}
