using System;
using System.Collections.Generic;
using System.Linq;
using MongoDB.Bson;
using MongoDB.Driver;
using MongoDB.Driver.Builders;
using FluentMongo.Linq;
using MongoDB.Driver.Builders;
using Resources;

namespace DraftCommander.Data
{
    public class StoreData<T> : IStore<T> where T:IDataItem
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

        public IEnumerable<T> Query(IMongoQuery mongoQuery )
        {
            return _mongoDatabase.GetCollection<T>(typeof (T).Name).Find(mongoQuery).AsEnumerable();
        }

        public IEnumerable<T> Where(Func<T, bool> predicate)
        {
            return _mongoDatabase.GetCollection<T>(typeof (T).Name).AsQueryable().Where(predicate);

        }

        public bool Write(T item)
        {
            _mongoDatabase.GetCollection<T>(typeof (T).Name).Insert(item);
            return true;
        }

        public bool Delete(T Item)
        {
            var query = MongoDB.Driver.Builders.Query.EQ("_id", Item.Id);
            var items = _mongoDatabase.GetCollection<T>(typeof (T).Name).Remove(query);
            
            return true;
        }
    }
}