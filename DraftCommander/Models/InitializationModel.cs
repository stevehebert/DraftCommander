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
        public InitializationModel(IStore<Player> playerCollection, IStore<RankingDetail> rankingCollection)
        {
            _playerCollection = playerCollection.FindAll().ToList();
            _rankingCollection = rankingCollection.FindAll().ToList();
        }

        public JsonResult GetData(Func<object, JsonRequestBehavior, JsonResult> jsonProcessor)
        {
            var items = from p in _playerCollection.AsQueryable()
                        join o in _rankingCollection.AsQueryable() on p.Id equals o.PlayerId
                        select new {p.Id, p.Position, p.Name, p.Team, o.Rank, o.Estimate};
            
             
            var rankingId = 1;

            
            var itemdata = (from p in items
                            select
                                new
                                {

                                    id = p.Id,
                                    cell = new object[] { p.Id, p.Position, p.Name, p.Team, p.Rank, p.Estimate}
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


        private int GetRank(int rankingId, int playerId, Func<RankingDetail, int> rankingDetailOperation)
        {
            var item =
                _rankingCollection.Where(p => p.RankingId == rankingId && p.PlayerId == playerId).
                    FirstOrDefault();

            return item != null ? rankingDetailOperation(item) : 0;
        }

    }
}