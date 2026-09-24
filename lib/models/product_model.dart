enum ProductCategory { mobilePhone, accessory, audio, caseProtection }

extension ProductCategoryX on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.mobilePhone:
        return 'موبایل / Phones';
      case ProductCategory.accessory:
        return 'کەل و پەل / Accessories';
      case ProductCategory.audio:
        return 'دەنگ / Audio & Beats';
      case ProductCategory.caseProtection:
        return 'کەڤەر و شوشە / Cases & Covers';
    }
  }
}

class Product {
  final String id;
  final String name;
  final String category;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final String sku;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.sku,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'stock': stock,
      'sku': sku,
      'image_url': imageUrl,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: (json['category'] as String?) ?? 'موبایل / Phones',
      buyPrice: (json['buy_price'] as num).toDouble(),
      sellPrice: (json['sell_price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      sku: json['sku'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}
