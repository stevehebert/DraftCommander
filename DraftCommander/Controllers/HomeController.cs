﻿using System.Threading;
using System.Web.Mvc;
using DraftCommander.Models;
using Resources;

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

        public ActionResult Index(string command)
        {
            ViewData["commander"] = ((command ?? string.Empty) == "SupremeRuler");

            return View(_initializationModel);
        }

        public ActionResult About()
        {
            return View();
        }

        public JsonResult AddBid(BidDetail bidDetail)
        {
            if (_initializationModel.StoreBid(bidDetail))
                return Json("GOOD", JsonRequestBehavior.DenyGet);
            else
                return Json("bad", JsonRequestBehavior.DenyGet);
        }

        public JsonResult DeleteBid( BidDeleteDetail bidDeleteDetail)
        {
            if (_initializationModel.DeleteBid(bidDeleteDetail))
                return Json("GOOD", JsonRequestBehavior.DenyGet);

            return Json("bad", JsonRequestBehavior.DenyGet);
        }
    }
}
