using System;
using System.Linq;
using MongoDB.Driver;
using Resources;

namespace DataLoader
{
    class Program
    {
// ReSharper disable UnusedParameter.Local
        static void Main(string[] args)
// ReSharper restore UnusedParameter.Local
        {
            var server = MongoServer.Create("mongodb://steve.hebert:grandam@staff.mongohq.com:10040/openlocker_db");
            var database = server.GetDatabase("openlocker_db");
            //server.GetDatabaseNames();
            //foreach (var item in server.GetDatabaseNames())
            //Console.Write(item);

            
            var collection = database.GetCollection("Players");
            
            foreach (var player in collection.FindAll().AsEnumerable())
                Console.Write(player);

            collection.RemoveAll();

            collection.Insert(new Player { Id = 1, Name = "Jennings, Greg", Position = "WR", Team = "SC-GBP" });
            collection.Insert(new Player { Id = 2, Name = "Johnston, Calvin", Position = "WR", Team = "DET" });
            collection.Insert(new Player { Id = 3, Name = "Peterson, Adrian", Position = "RB", Team = "MIN" });
            collection.Insert(new Player { Id = 4, Name = "Finley, Jermichael", Position = "TE", Team = "SC-GBP" });
            collection.Insert(new Player { Id = 5, Name = "Hebert, Bobby", Position = "QB", Team = "NO" });


            collection = database.GetCollection("Auctions");
            collection.RemoveAll();
            collection.Insert(new Auction { Id = 1, Name = "EastSide" });

            collection = collection.Database.GetCollection("Owners");
            collection.RemoveAll();
            collection.Insert(new Owner { AuctionId = 1, Id = 1, Name = "Sponge Bobs" });
            collection.Insert(new Owner { AuctionId = 1, Id = 2, Name = "Prom Queens" });
            collection.Insert(new Owner { AuctionId = 1, Id = 3, Name = "Terminators" });


            collection = collection.Database.GetCollection("Rankings");
            collection.RemoveAll();
            collection.Insert(new Ranking { Id = 1, Name = "Fanball - 10 player" });

            collection = collection.Database.GetCollection("RankingDetails");
            collection.RemoveAll();
            collection.Insert(new RankingDetail { RankingId = 1, PlayerId = 1, Estimate = 25, Rank = 1 });
            collection.Insert(new RankingDetail { RankingId = 1, PlayerId = 2, Estimate = 15, Rank = 7 });
            collection.Insert(new RankingDetail { RankingId = 1, PlayerId = 3, Estimate = 12, Rank = 9 });
            collection.Insert(new RankingDetail { RankingId = 1, PlayerId = 4, Estimate = 11, Rank = 19 });

        }
    }
}
