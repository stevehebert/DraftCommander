using System;
using System.Linq;
using System.Web.Mvc;
using Resources;

namespace DraftCommander.Models
{
    public class InitializationModel
    {
        private readonly IStore<Player> _playerCollection;
        public InitializationModel(IStore<Player> playerCollection)
        {
            _playerCollection = playerCollection;
        }

        public JsonResult GetData(Func<object, JsonRequestBehavior, JsonResult> jsonProcessor)
        {
            var itemdata = (from p in _playerCollection.FindAll().AsQueryable()
                            select
                                new
                                {
                                    id = p.Id,
                                    cell = new object[] { p.Id, p.Position, p.Name, p.Team, p.Id, p.Id }
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
    }
}