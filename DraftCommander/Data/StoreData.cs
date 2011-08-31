using System;
using System.Collections.Generic;
using System.Linq;
using MongoDB.Driver;
using FluentMongo.Linq;
using MongoDB.Driver.Builders;
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
    }
}