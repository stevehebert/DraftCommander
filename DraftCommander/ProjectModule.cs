using Autofac;
using DraftCommander.Data;

namespace DraftCommander
{
    public class ProjectModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterModule( new RegistrationModule());
            builder.RegisterModule(new Models.RegistrationModule());
        }
    }
}