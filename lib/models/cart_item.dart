import 'product_model.dart';

class CartItem {
  final Product product;
  int quantity;
  double? customPrice;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.customPrice,
  });

  double get unitPrice => customPrice ?? product.sellPrice;
  double get total => unitPrice * quantity;

  CartItem copyWith({int? quantity, double? customPrice}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      customPrice: customPrice ?? this.customPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'customPrice': customPrice,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] as int,
      customPrice: json['customPrice'] != null ? (json['customPrice'] as num).toDouble() : null,
    );
  }
}
