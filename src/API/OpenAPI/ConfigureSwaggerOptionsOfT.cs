using Asp.Versioning.ApiExplorer;

namespace API.OpenAPI
{
    public class ConfigureSwaggerOptions<T> : ConfigureSwaggerOptions where T : class
    {
        public ConfigureSwaggerOptions(IApiVersionDescriptionProvider provider) : base(provider) { }

        protected override string GetName()
        {
            var name = typeof(T).Assembly?.GetName().Name;
            return GetPrettyName(name);
        }
    }
}
