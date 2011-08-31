using Autofac;
using MongoDB.Driver;
using Resources;

namespace DraftCommander.Data
{
    public class RegistrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterInstance(
                //MongoServer.Create("mongodb://localhost:27017/")).
                MongoServer.Create("mongodb://steve.hebert:grandam@staff.mongohq.com:10040/openlocker_db")).
                SingleInstance();

            builder.Register(c => c.Resolve<MongoServer>().GetDatabase("openlocker_db")).SingleInstance();

            builder.RegisterGeneric(typeof(StoreData<>)).As(typeof(IStore<>)).InstancePerDependency();
        }
    }
}