using System.Linq;
using MongoDB.Driver;
using FluentMongo.Linq;
using Resources;

namespace DraftCommander.Data
{
    public class StoreData<T> : IStore<T>
    {
        private readonly MongoDatabase _mongoDatabase;

        public StoreData(MongoDatabase database)
        {
            _mongoDatabase = database;
        }

        public IQueryable<T> FindAll()
        {
            
            return _mongoDatabase.GetCollection<T>(typeof (T).Name).AsQueryable();
        }
    }
}