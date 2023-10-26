using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private static int _lastId = 6;
        private static readonly List<Product> _products = new()
        {
            new Product(1, "Product 1", "The newest Product 1!", "Sku1"),
            new Product(2, "Product 2", "The newest Product 2!", "Sku2"),
            new Product(3, "Product 3", "The newest Product 3!", "Sku3"),
            new Product(4, "Product 4", "The newest Product 4!", "Sku4"),
            new Product(5, "Product 5", "The newest Product 5!", "Sku5"),
            new Product(6, "Product 6", "The newest Product 6!", "Sku6"),
        };

        private static readonly List<Product> _productsv2 = new()
        {
            new Product(1, "Product 1", "The newest Product 1!", "Sku1"),
            new Product(2, "Product 2", "The newest Product 2!", "Sku2"),
            new Product(3, "Product 3", "The newest Product 3!", "Sku3"),
            new Product(4, "Product 4", "The newest Product 4!", "Sku4"),
            new Product(5, "Product 5", "The newest Product 5!", "Sku5"),
            new Product(6, "Product 6", "The newest Product 6!", "Sku6"),
            new Product(7, "Product 7", "The newest Product 7!", "Sku7"),
        };

        [HttpGet]
        [Produces("application/json")]
        [ProducesResponseType(typeof(IEnumerable<Product>), 200)]
        public IActionResult Get()
        {
            return Ok(_products.AsEnumerable());
        }

        [HttpGet("{id:int}")]
        [Produces("application/json")]
        [ProducesResponseType(typeof(Product), 200)]
        [ProducesResponseType(404)]
        public IActionResult Get(int id)
        {
            var product = _products.SingleOrDefault(x => x.Id == id);
            return product != default ? Ok(product) : NotFound();
        }

        [HttpPost]
        [Consumes("application/json")]
        [Produces("application/json")]
        [ProducesResponseType(typeof(Product), 201)]
        [ProducesResponseType(400)]
        public IActionResult Create([FromBody]Product product)
        {
            var id = Interlocked.Increment(ref _lastId);
            var newProduct = new Product(id, product.Name, product.Sku, product.Description);
            _products.Add(newProduct);
            return CreatedAtAction(nameof(Get), new { id }, newProduct);
        }

        [HttpPatch("{id:int}")]
        [Consumes("application/json")]
        [ProducesResponseType(204)]
        [ProducesResponseType(400)]
        [ProducesResponseType(404)]
        public IActionResult Update(int id, [FromBody] Product product)
        {
            var existing = _products.SingleOrDefault(x => x.Id == id);
            if (existing != default)
            {
                var newProduct = existing.Merge(product);
                var i = _products.IndexOf(existing);
                _products[i] = newProduct;
                return NoContent();
            }
            else
            {
                return NotFound();
            }
        }

        [HttpDelete("{id:int}")]
        [Consumes("application/json")]
        [ProducesResponseType(204)]
        [ProducesResponseType(404)]
        public IActionResult Delete(int id)
        {
            var existing = _products.SingleOrDefault(x => x.Id == id);
            if (existing != default)
            {
                _products.Remove(existing);
                return NoContent();
            }
            else
            {
                return NotFound();
            }
        }
    }
}
