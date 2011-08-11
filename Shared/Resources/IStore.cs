using MongoDB.Driver;

namespace Resources
{
    public interface IStore<T>
    {
        MongoCollection<T> FindAll();
    }
}
