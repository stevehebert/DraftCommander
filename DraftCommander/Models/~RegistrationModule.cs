using Autofac;

namespace DraftCommander.Models
{
    public class RegistrationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<InitializationModel>();
        }
    }
}