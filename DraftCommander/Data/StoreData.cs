using MongoDB.Driver;
using Resources;

namespace DraftCommander.Data
{
    public class StoreData<T> : IStore<T>
    {
        private MongoDatabase _mongoDatabase;

        public StoreData(MongoDatabase database)
        {
            _mongoDatabase = database;
        }
        public MongoCollection<T> FindAll()
        {
            return _mongoDatabase.GetCollection<T>(typeof (T).Name);
        }
    }
}