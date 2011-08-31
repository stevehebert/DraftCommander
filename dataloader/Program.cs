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
            //var server = MongoServer.Create("mongodb://localhost:27017/");
            server.CreateDatabaseSettings("openlocker_db");

            var database = server.GetDatabase("openlocker_db");
            
            var collection = database.GetCollection<Player>(typeof(Player).Name);
            
            foreach (var player in collection.FindAll().AsEnumerable())
                Console.Write(player);

            collection.RemoveAll();

            collection.Insert(new Player { Id = 1, Name = "Jennings, Greg", Position = "WR", Team = "SC-GBP" });
            collection.Insert(new Player { Id = 2, Name = "Johnston, Calvin", Position = "WR", Team = "DET" });
            collection.Insert(new Player { Id = 3, Name = "Peterson, Adrian", Position = "RB", Team = "MIN" });
            collection.Insert(new Player { Id = 4, Name = "Finley, Jermichael", Position = "TE", Team = "SC-GBP" });
            collection.Insert(new Player { Id = 5, Name = "Hebert, Bobby", Position = "QB", Team = "NO" });


            var collection2 = database.GetCollection<Auction>(typeof(Auction).Name);
            collection2.RemoveAll();
            collection2.Insert(new Auction { Id = 1, Name = "EastSide" });

            var collection3 = database.GetCollection<Owner>(typeof(Owner).Name);
            collection3.RemoveAll();
            collection3.Insert(new Owner { AuctionId = 1, Id = 1, Name = "Sponge Bobs - Bob Gross" });
            collection3.Insert(new Owner { AuctionId = 1, Id = 2, Name = "Prom Queens - Steve Hebert" });
            collection3.Insert(new Owner { AuctionId = 1, Id = 3, Name = "Terminators - Dave Houghton" });
            collection3.Insert(new Owner { AuctionId = 1, Id = 4, Name = "D-Jabs - Bill Benert" });
            collection3.Insert(new Owner { AuctionId = 1, Id = 5, Name = "No More Scum - Tom Houghton" });
            collection3.Insert(new Owner { AuctionId = 1, Id = 6, Name = "Spill Kings - Dave Timm" });
            collection3.Insert(new Owner { AuctionId = 1, Id = 7, Name = "Sodbusters - Larry Fitzpatrick" });
            collection3.Insert(new Owner { AuctionId = 1, Id = 8, Name = "Superstars - Steve Sheahan" });
            collection3.Insert(new Owner { AuctionId = 1, Id = 9, Name = "Wolfpack - Wally Kelsey" });
            collection3.Insert(new Owner { AuctionId = 1, Id = 10, Name = "Zephyrs - Erik Metling" });

            var collection4 = database.GetCollection<Ranking>(typeof(Ranking).Name);
            collection4.RemoveAll();
            collection4.Insert(new Ranking { Id = 1, Name = "Fanball - 10 player" });

            var collection5 = database.GetCollection<RankingDetail>(typeof(RankingDetail).Name);
            collection5.RemoveAll();
            collection5.Insert(new RankingDetail { Id = 1, RankingId = 1, PlayerId = 1, Estimate = 25, Rank = 1 });
            collection5.Insert(new RankingDetail { Id = 2, RankingId = 1, PlayerId = 2, Estimate = 15, Rank = 7 });
            collection5.Insert(new RankingDetail { Id = 3, RankingId = 1, PlayerId = 3, Estimate = 12, Rank = 9 });
            collection5.Insert(new RankingDetail { Id = 4, RankingId = 1, PlayerId = 4, Estimate = 11, Rank = 19 });

            var collection6 = database.GetCollection<BidDetail>(typeof(BidDetail).Name);
            collection6.RemoveAll();
            collection6.Insert(new BidDetail { Id = 0, AuctionId = 1, PlayerId = 2, OwnerId = 5, BidAmount = 10});
            collection6.Insert(new BidDetail { Id = 1, AuctionId = 1, PlayerId = 5, OwnerId = 4, BidAmount = 5 });

        }
    }
}
