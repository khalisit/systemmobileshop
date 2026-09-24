import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/cart_item.dart';
import '../core/config/supabase_config.dart';

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<Product>>(() {
      return InventoryNotifier();
    });

class InventoryNotifier extends AsyncNotifier<List<Product>> {
  SupabaseClient? get _supabase =>
      SupabaseConfig.isConfigured() ? Supabase.instance.client : null;

  @override
  Future<List<Product>> build() async {
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە یان کلیلی Supabase ڕاست نییە');
    }

    final response = await _supabase!.from('products').select().order('name', ascending: true);
    final list = (response as List).map((e) => Product.fromJson(e)).toList();
    return list;
  }

  Future<void> refreshProducts() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchProducts());
  }

  Future<void> addProduct(Product product) async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    state = const AsyncLoading();
    try {
      await _supabase!.from('products').insert(product.toJson());
      final updatedList = await _fetchProducts();
      state = AsyncData(updatedList);
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchProducts());
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    state = const AsyncLoading();
    try {
      await _supabase!
          .from('products')
          .update(product.toJson())
          .eq('id', product.id);
      final updatedList = await _fetchProducts();
      state = AsyncData(updatedList);
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchProducts());
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    state = const AsyncLoading();
    try {
      await _supabase!.from('products').delete().eq('id', id);
      final updatedList = await _fetchProducts();
      state = AsyncData(updatedList);
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchProducts());
      rethrow;
    }
  }

  /// Automatically adjusts inventory stock when a sale receipt is added, edited, or deleted.
  Future<void> adjustStockForReceiptEdit({
    required List<CartItem> oldItems,
    required List<CartItem> newItems,
  }) async {
    List<Product> currentProducts = state.value ?? [];
    if (currentProducts.isEmpty && _supabase != null) {
      try {
        currentProducts = await _fetchProducts();
      } catch (_) {}
    }

    final Map<String, int> stockDeltas = {};

    // Restore old quantities (+oldQty)
    for (final item in oldItems) {
      stockDeltas[item.product.id] = (stockDeltas[item.product.id] ?? 0) + item.quantity;
    }

    // Deduct new quantities (-newQty)
    for (final item in newItems) {
      stockDeltas[item.product.id] = (stockDeltas[item.product.id] ?? 0) - item.quantity;
    }

    for (final entry in stockDeltas.entries) {
      final pid = entry.key;
      final delta = entry.value;
      if (delta == 0) continue;

      final idx = currentProducts.indexWhere((p) => p.id == pid);
      if (idx != -1) {
        final p = currentProducts[idx];
        final newQty = (p.stock + delta).clamp(0, 999999);

        if (_supabase != null) {
          try {
            await _supabase!
                .from('products')
                .update({'stock': newQty})
                .eq('id', pid);
          } catch (_) {}
        }
      }
    }

    if (_supabase != null) {
      try {
        final updatedList = await _fetchProducts();
        state = AsyncData(updatedList);
      } catch (_) {}
    }
  }
}
