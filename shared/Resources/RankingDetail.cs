namespace Resources
{
    public class RankingDetail : IDataItem
    {
        public int Id { get; set; }
        public int RankingId { get; set; }
        public int PlayerId { get; set; }
        public int Rank { get; set; }
        public int Estimate { get; set; }
    }
}