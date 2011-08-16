namespace Resources
{
    public class BidDetail
    {
        public long Id { get; set; }
        public int OwnerId { get; set; }
        public int AuctionId { get; set; }
        public int PlayerId { get; set; }
        public int BidAmount { get; set; }
    }
}
