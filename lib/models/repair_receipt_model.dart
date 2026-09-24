import 'package:uuid/uuid.dart';

class RepairReceiptModel {
  final String id;
  final DateTime date;
  final String customerName;
  final String customerPhone;
  final String repairType;
  final double itemCost;
  final double laborCost;
  final double totalPrice;

  RepairReceiptModel({
    String? id,
    DateTime? date,
    required this.customerName,
    required this.customerPhone,
    required this.repairType,
    this.itemCost = 0.0,
    this.laborCost = 0.0,
    double? totalPrice,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        totalPrice = totalPrice ?? (itemCost + laborCost);

  RepairReceiptModel copyWith({
    String? customerName,
    String? customerPhone,
    String? repairType,
    double? itemCost,
    double? laborCost,
    double? totalPrice,
  }) {
    return RepairReceiptModel(
      id: id,
      date: date,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      repairType: repairType ?? this.repairType,
      itemCost: itemCost ?? this.itemCost,
      laborCost: laborCost ?? this.laborCost,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'repair_type': repairType,
      'item_cost': itemCost,
      'labor_cost': laborCost,
      'total_price': totalPrice,
    };
  }

  factory RepairReceiptModel.fromJson(Map<String, dynamic> json) {
    return RepairReceiptModel(
      id: (json['id'] as String?) ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      customerName: (json['customer_name'] as String?) ?? '',
      customerPhone: (json['customer_phone'] as String?) ?? '',
      repairType: (json['repair_type'] as String?) ?? '',
      itemCost: (json['item_cost'] as num?)?.toDouble() ?? 0.0,
      laborCost: (json['labor_cost'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
