using ProductAPI.Models;
using ProductAPI.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Agregar servicios
builder.Services.AddSingleton<ProductRepository>();
builder.Services.AddControllers();
// Exponer metadata OpenAPI (endpoints) sin depender de Swashbuckle
builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

// Configurar el pipeline HTTP
// Configurar el pipeline HTTP
// Siempre mapear el documento OpenAPI para que pueda ser consumido por Swagger UI estático
// Serve a static OpenAPI JSON document at /openapi to support Swagger UI without Swashbuckle
var _openApiJson = @"{
  ""openapi"": ""3.0.1"",
  ""info"": { ""title"": ""ProductAPI"", ""version"": ""v1"" },
  ""paths"": {
    ""/api/products"": {
      ""get"": {
        ""summary"": ""Get all products"",
        ""responses"": { ""200"": { ""description"": ""OK"" } }
      }
    },
    ""/api/products/{id}"": {
      ""get"": {
        ""summary"": ""Get product by id"",
        ""parameters"": [{ ""name"": ""id"", ""in"": ""path"", ""required"": true, ""schema"": { ""type"": ""integer"" } }],
        ""responses"": { ""200"": { ""description"": ""OK"" }, ""404"": { ""description"": ""Not found"" } }
      }
    },
    ""/api/products/health"": {
      ""get"": { ""summary"": ""Health check"", ""responses"": { ""200"": { ""description"": ""OK"" } } }
    }
  }
}";

app.MapGet("/openapi", () => Results.Text(_openApiJson, "application/json"));

// Servir una UI de Swagger estática (desde CDN) para entornos que no usan Swashbuckle
var _swaggerHtml = @"<!doctype html>
<html>
  <head>
    <meta charset='utf-8'/>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>ProductAPI - Swagger UI</title>
    <link rel='stylesheet' href='https://unpkg.com/swagger-ui-dist/swagger-ui.css' />
  </head>
  <body>
    <div id='swagger-ui'></div>
    <script src='https://unpkg.com/swagger-ui-dist/swagger-ui-bundle.js'></script>
    <script>
      window.onload = function() {
        SwaggerUIBundle({
          url: '/openapi',
          dom_id: '#swagger-ui',
          presets: [SwaggerUIBundle.presets.apis],
          layout: 'BaseLayout'
        });
      };
    </script>
  </body>
</html>";

app.MapGet("/swagger", () => Results.Content(_swaggerHtml, "text/html"));

app.MapGet("/swagger/index.html", () => Results.Redirect("/swagger", true));

app.UseHttpsRedirection();
app.MapControllers();

// Endpoint de health check
app.MapGet("/api/products/health", () => 
    Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
.WithName("HealthCheck");

app.Run();
