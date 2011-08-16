using System;
using System.Collections.Generic;
using System.Linq;
using MongoDB.Driver;

namespace Resources
{
    public interface IStore<T>
    {
        IQueryable<T> FindAll();
        IEnumerable<T> Query(IMongoQuery mongoQuery);
        IEnumerable<T> Where(Func<T, bool> predicate);
    }
}
