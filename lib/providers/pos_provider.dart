import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/receipt_model.dart';
import '../models/cart_item.dart';
import 'inventory_provider.dart';

// ─── POS State ───────────────────────────────────────────────────────
class PosState {
  final List<CartItem> cart;
  final String searchQuery;
  final String? filterCategory;
  final String paymentMethod; // 'نەقد', 'قەرز'
  final double discount; // discount value
  final String discountType; // 'amount' or 'percent'
  final String customerName;
  final String customerPhone;
  final double? paidAmount;
  final String? editingReceiptId;

  const PosState({
    this.cart = const [],
    this.searchQuery = '',
    this.filterCategory,
    this.paymentMethod = 'نەقد',
    this.discount = 0,
    this.discountType = 'amount',
    this.customerName = '',
    this.customerPhone = '',
    this.paidAmount,
    this.editingReceiptId,
  });

  double get subtotal => cart.fold(0, (sum, item) => sum + item.total);

  double get calculatedDiscount {
    if (discountType == 'percent') {
      return subtotal * (discount / 100);
    }
    return discount;
  }

  double get grandTotal => (subtotal - calculatedDiscount).clamp(0, double.infinity);
  int get itemCount => cart.fold(0, (sum, item) => sum + item.quantity);

  double get actualPaidAmount => paidAmount ?? (paymentMethod == 'نەقد' ? grandTotal : 0.0);
  double get remainingDebt => (grandTotal - actualPaidAmount).clamp(0.0, double.infinity);

  PosState copyWith({
    List<CartItem>? cart,
    String? searchQuery,
    String? filterCategory,
    bool clearFilter = false,
    String? paymentMethod,
    double? discount,
    String? discountType,
    String? customerName,
    String? customerPhone,
    double? paidAmount,
    bool clearPaidAmount = false,
    String? editingReceiptId,
    bool clearEditingReceiptId = false,
  }) {
    return PosState(
      cart: cart ?? this.cart,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCategory: clearFilter ? null : (filterCategory ?? this.filterCategory),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      paidAmount: clearPaidAmount ? null : (paidAmount ?? this.paidAmount),
      editingReceiptId: clearEditingReceiptId ? null : (editingReceiptId ?? this.editingReceiptId),
    );
  }
}

// ─── POS Notifier ────────────────────────────────────────────────────
class PosNotifier extends StateNotifier<PosState> {
  PosNotifier() : super(const PosState());

  void addToCart(Product product) {
    final existing = state.cart.indexWhere((c) => c.product.id == product.id);
    if (existing >= 0) {
      final updated = [...state.cart];
      updated[existing] = CartItem(
        product: product,
        quantity: updated[existing].quantity + 1,
        customPrice: updated[existing].customPrice,
      );
      state = state.copyWith(cart: updated);
    } else {
      state = state.copyWith(cart: [...state.cart, CartItem(product: product)]);
    }
  }

  void removeFromCart(String productId) {
    state = state.copyWith(cart: state.cart.where((c) => c.product.id != productId).toList());
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      removeFromCart(productId);
      return;
    }
    final updated = state.cart.map((c) {
      if (c.product.id == productId) {
        return CartItem(product: c.product, quantity: qty, customPrice: c.customPrice);
      }
      return c;
    }).toList();
    state = state.copyWith(cart: updated);
  }

  void updatePrice(String productId, double price) {
    final updated = state.cart.map((c) {
      if (c.product.id == productId) {
        return CartItem(product: c.product, quantity: c.quantity, customPrice: price);
      }
      return c;
    }).toList();
    state = state.copyWith(cart: updated);
  }

  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q);

  void setFilter(String? cat) {
    if (cat == null || cat.isEmpty) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterCategory: cat);
    }
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(
      paymentMethod: method,
      clearPaidAmount: true,
    );
  }

  void setPaidAmount(double? amount) => state = state.copyWith(paidAmount: amount);
  void setDiscount(double d) => state = state.copyWith(discount: d);
  void setDiscountType(String t) => state = state.copyWith(discountType: t);
  void setCustomerName(String n) => state = state.copyWith(customerName: n);
  void setCustomerPhone(String p) => state = state.copyWith(customerPhone: p);

  void clearCart() => state = state.copyWith(cart: []);
  
  void clear() => state = const PosState();

  void loadReceipt(ReceiptModel receipt) {
    state = PosState(
      cart: receipt.items,
      searchQuery: '',
      filterCategory: null,
      paymentMethod: receipt.paymentMethod,
      discount: receipt.discount,
      discountType: receipt.discountType,
      customerName: receipt.customerName,
      customerPhone: receipt.customerPhone,
      paidAmount: receipt.paidAmount,
      editingReceiptId: receipt.id,
    );
  }
}

final posProvider = StateNotifierProvider<PosNotifier, PosState>((ref) => PosNotifier());

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final pos = ref.watch(posProvider);
  final allProductsAsync = ref.watch(inventoryProvider);
  
  return allProductsAsync.whenData((allProducts) {
    return allProducts.where((p) {
      final matchesSearch = pos.searchQuery.isEmpty ||
          p.name.toLowerCase().contains(pos.searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(pos.searchQuery.toLowerCase());
      final matchesCat = pos.filterCategory == null ||
          pos.filterCategory!.isEmpty ||
          p.category.trim().toLowerCase() == pos.filterCategory!.trim().toLowerCase();
      return matchesSearch && matchesCat;
    }).toList();
  });
});
