namespace API
{
    public record class Product(int Id, string? Name, string? Description, string? Sku)
    {
        public Product Merge(Product newProduct)
        {
            return new Product(Id, newProduct.Name ?? Name, newProduct.Description ?? Description, newProduct.Sku ?? Sku);
        }
    }
}
