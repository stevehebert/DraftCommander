namespace Resources
{
    public interface IDataItem
    {
        int Id { get; set; }
    }
    public class BidDetail : IDataItem
    {
        public int Id { get; set; }
        public int OwnerId { get; set; }
        public int AuctionId { get; set; }
        public int PlayerId { get; set; }
        public int BidAmount { get; set; }
    }
}
