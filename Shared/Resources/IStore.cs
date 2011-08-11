using System.Linq;

namespace Resources
{
    public interface IStore<T>
    {
        IQueryable<T> FindAll();
    }
}
