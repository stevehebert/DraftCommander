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
        public int id { get; set; }
        public IEnumerable<object> cell { get; set; }
        
        public PlayerRow(int id, string position, string name, string team, int? rank, int? estimate, string owner, int? bidAmount)
        {
            this.id = id;

            cell = new object[] {id, position, name, team, rank, estimate, owner, bidAmount};
        }
    }
}