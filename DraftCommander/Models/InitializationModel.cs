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

        public bool StoreBid(BidDetail bidDetail)
        {
            return _bidCollection.Write(bidDetail);
        }

        private IEnumerable<PlayerRow> GetPlayerRows(int auctionId)
        {
            var items = (from p in _playerCollection.AsQueryable()
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
                             BidAmount = new int?()
                         });

            return (from p in items
                            select
                                new PlayerRow(p.Id, p.Position, p.Name, p.Team, p.Rank, p.Estimate, p.Owner,
                                              p.BidAmount));
        }

        private IEnumerable<OwnerInfo> GetOwnerRows(int auctionId)
        {
            var owners = from p in _ownerCollection.AsQueryable()
                         where p.AuctionId == 1
                         select new { p.Id, p.Name};

            return from p in owners
                   select new OwnerInfo {Id = p.Id, OwnerRow = new OwnerRow {Name = p.Name}};
        }

        public JsonResult BigGulp(int auctionId,  Func<object, JsonResult> jsonProcessor)
        {
            var item = new
                           {
                               type = "LOAD",
                               PlayerData = GetPlayerRows(auctionId),
                               OwnerData = GetOwnerRows(auctionId),
                               AuctionRules = GetAuctionRules(auctionId),
                               BidHistory = from p in _bidCollection.Where(p => p.AuctionId == auctionId)
                                            select new {type = "BID", p.OwnerId, p.PlayerId, p.BidAmount, p.Id}
                           };

            return jsonProcessor(item);
        }

        private AuctionRules GetAuctionRules(int auctionId)
        {
            return new AuctionRules
                       {
                           StartingFunds = 100,
                           MinBid = 1,
                           MinPlayerCount = 13,
                           Positions = new[]
                                           {
                                               new PositionSummary {Position = "QB", Count = 1},
                                               new PositionSummary {Position = "RB", Count = 2},
                                               new PositionSummary {Position = "WR", Count = 2},
                                               new PositionSummary {Position = "TE", Count = 1},
                                               new PositionSummary {Position = "K", Count = 1},
                                               new PositionSummary {Position = "DEF", Count = 1}
                                           }
                       };
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