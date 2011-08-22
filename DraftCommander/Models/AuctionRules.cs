using System.Collections.Generic;

namespace DraftCommander.Models
{
    public class AuctionRules
    {
        public int StartingFunds { get; set; }
        public int MinBid { get; set; }
        public int MinPlayerCount { get; set; }

        public IEnumerable<PositionSummary> Positions { get; set; }
    }

    public class PositionSummary
    {
        public string Position { get; set; }
        public int Count { get; set; }
    }

    public class PlayerRow
    {
        public int Id { get; private set; }
        public string Position { get; private set; }
        public string Name { get; private set; }
        public string Team { get; private set; }
        public int? Rank { get; private set; }
        public int? Estimate { get; private set; }
        public string Owner { get; private set; }
        public int? BidAmount;

        public IEnumerable<object> cell { get; set; }
        
        public PlayerRow(int id, string position, string name, string team, int? rank, int? estimate, string owner, int? bidAmount)
        {
            Id = id;
            Position = position;
            Name = name;
            Team = team;
            Rank = rank;
            Estimate = estimate;
            Owner = owner;
            BidAmount = bidAmount;

            cell = new object[] {id, position, name, team, rank, estimate, owner, bidAmount};
        }
    }
}