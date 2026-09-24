import 'package:uuid/uuid.dart';
import 'cart_item.dart';

class ReceiptModel {
  final String id;
  final DateTime date;
  final String customerName;
  final String customerPhone;
  final List<CartItem> items;
  final double discount;
  final String discountType; // 'amount' or 'percent'
  final double grandTotal;
  final double paidAmount;
  final String paymentMethod; // 'نەقد', 'قەرز'

  ReceiptModel({
    String? id,
    DateTime? date,
    this.customerName = '',
    this.customerPhone = '',
    required this.items,
    this.discount = 0.0,
    this.discountType = 'amount',
    required this.grandTotal,
    double? paidAmount,
    this.paymentMethod = 'نەقد',
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        paidAmount = paidAmount ?? (paymentMethod == 'نەقد' ? grandTotal : 0.0);

  ReceiptModel copyWith({
    String? customerName,
    String? customerPhone,
    List<CartItem>? items,
    double? discount,
    String? discountType,
    double? grandTotal,
    double? paidAmount,
    String? paymentMethod,
  }) {
    return ReceiptModel(
      id: id,
      date: date,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get remainingAmount {
    final rem = grandTotal - paidAmount;
    return rem < 0 ? 0.0 : rem;
  }

  bool get isFullyPaid => remainingAmount <= 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'items': items.map((i) => i.toJson()).toList(),
      'discount': discount,
      'discount_type': discountType,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'payment_method': paymentMethod,
    };
  }

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    final gt = (json['grand_total'] as num?)?.toDouble() ?? 0.0;
    final pm = (json['payment_method'] as String?) ?? 'نەقد';
    final defaultPaid = pm == 'نەقد' ? gt : 0.0;

    return ReceiptModel(
      id: (json['id'] as String?) ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      customerName: (json['customer_name'] as String?) ?? '',
      customerPhone: (json['customer_phone'] as String?) ?? '',
      items: (json['items'] as List?)
              ?.map((i) => CartItem.fromJson(Map<String, dynamic>.from(i as Map)))
              .toList() ??
          [],
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountType: (json['discount_type'] as String?) ?? 'amount',
      grandTotal: gt,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? defaultPaid,
      paymentMethod: pm,
    );
  }
}
