using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Resources;

namespace DraftCommander.Models
{
    public class InitializationModel
    {
        private readonly List<Player> _playerCollection;
        private readonly List<RankingDetail> _rankingCollection;
        private readonly List<Owner> _ownerCollection;
        private readonly IStore<BidDetail> _bidCollection;

        public InitializationModel(IStore<Player> playerCollection, IStore<RankingDetail> rankingCollection, IStore<Owner> ownerCollection, IStore<BidDetail> bidCollection)
        {
            _playerCollection = playerCollection.FindAll().ToList();
            _rankingCollection = rankingCollection.FindAll().ToList();
            _ownerCollection = ownerCollection.FindAll().ToList();
            _bidCollection = bidCollection;
        }


        public JsonResult GetBidData(int auctionId, Func<object, JsonResult> jsonProcessor)
        {
            var contents = from p in _bidCollection.Where(p => p.AuctionId == auctionId)
                           select new {type = "BID", p.OwnerId, p.PlayerId, p.BidAmount};

            var jsonData = new {records = contents};

            return jsonProcessor(jsonData);
        }

        public JsonResult GetOwnerData(Func<object, JsonRequestBehavior, JsonResult> jsonProcessor)
        {
            var owners = from p in _ownerCollection.AsQueryable()
                         where p.AuctionId == 1
                         select new {p.Id, p.Name, CurrentFunds = 100, PlayersLeft = 13, RequiredPlayers = 8, NeededPlayers = "1 QB, 2 RB"};

            var itemdata = from p in owners
                           select
                               new
                                   {
                                       id = p.Id,
                                       cell =
                               new object[]
                                   {p.Name, p.CurrentFunds, p.PlayersLeft, p.RequiredPlayers, p.NeededPlayers}
                                   };

            var jsonData = new
                               {
                                   total = 1,
                                   page = 1,
                                   records = itemdata.Count(),
                                   rows = itemdata
                               };

            return jsonProcessor(jsonData, JsonRequestBehavior.AllowGet);


        }

        public JsonResult GetData(Func<object, JsonRequestBehavior, JsonResult> jsonProcessor)
        {
            var items = from p in _playerCollection.AsQueryable()
                        join o in _rankingCollection.AsQueryable() on p.Id equals o.PlayerId into outer
                        from o in outer.DefaultIfEmpty()
                        select new
                                   {
                                       p.Id,
                                       p.Position,
                                       p.Name,
                                       p.Team,
                                       Rank = ((o != null ? new int?(o.Rank) : null)),
                                       Estimate = (o != null ? new int?(o.Estimate) : null),
                                       Owner = string.Empty,
                                       BidAmount = string.Empty
                                   };
            
             
            var rankingId = 1;

            
            var itemdata = (from p in items
                            select
                                new
                                {

                                    id = p.Id,
                                    cell = new object[] { p.Id, p.Position, p.Name, p.Team, p.Rank, p.Estimate, p.Owner, p.BidAmount}
                                }).ToArray();


            var jsonData = new
            {
                total = 1,
                page = 1,
                records = 5,
                rows = itemdata
            };

            return jsonProcessor(jsonData, JsonRequestBehavior.AllowGet);
        }

        public IEnumerable<KeyValuePair<int, string>> PlayerList
        {
            get
            {
                return from p in _playerCollection.AsQueryable()
                       orderby p.Name
                       select new KeyValuePair<int, string>(p.Id, p.Name);
            }
        }

    }
}