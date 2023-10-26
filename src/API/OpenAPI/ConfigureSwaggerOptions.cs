using Asp.Versioning.ApiExplorer;
using Microsoft.Extensions.Options;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Reflection;

namespace API.OpenAPI;

public class ConfigureSwaggerOptions : IConfigureOptions<SwaggerGenOptions>
{
    private readonly IApiVersionDescriptionProvider _provider;

    public ConfigureSwaggerOptions(IApiVersionDescriptionProvider provider)
    {
        _provider = provider;
    }

    public void Configure(SwaggerGenOptions options)
    {
        var name = GetName();
        foreach (var description in _provider.ApiVersionDescriptions)
        {
            options.SwaggerDoc(
                description.GroupName,
                new OpenApiInfo()
                {
                    Title = name,
                    Description = name,
                    Version = description.ApiVersion.ToString(),
                });
        }
    }

    protected virtual string GetName()
    {
        var assembly = Assembly.GetEntryAssembly();
        var name = assembly?.GetName().Name;
        return GetPrettyName(name);
    }

    protected string GetPrettyName(string? name)
    {
        var title = name != null ? $"{name}" : "API";

        return title
            .Replace('.', ' ')
            .Replace("Service", "", StringComparison.OrdinalIgnoreCase)
            .Replace("Application", "", StringComparison.OrdinalIgnoreCase);
    }
}
