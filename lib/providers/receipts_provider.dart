import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receipt_model.dart';
import '../core/config/supabase_config.dart';
import 'inventory_provider.dart';

final receiptsProvider =
    AsyncNotifierProvider<ReceiptsNotifier, List<ReceiptModel>>(() {
      return ReceiptsNotifier();
    });

class ReceiptsNotifier extends AsyncNotifier<List<ReceiptModel>> {
  final List<ReceiptModel> _localReceipts = [];

  SupabaseClient? get _supabase =>
      SupabaseConfig.isConfigured() ? Supabase.instance.client : null;

  @override
  Future<List<ReceiptModel>> build() async {
    return _fetchReceipts();
  }

  Future<List<ReceiptModel>> _fetchReceipts() async {
    if (_supabase == null) return _localReceipts;

    try {
      final response = await _supabase!
          .from('receipts')
          .select()
          .order('date', ascending: false);
      final list = (response as List).map((e) => ReceiptModel.fromJson(e)).toList();
      if (list.isNotEmpty) {
        _localReceipts.clear();
        _localReceipts.addAll(list);
        return list;
      }
      return _localReceipts;
    } catch (e) {
      return _localReceipts;
    }
  }

  Future<void> refreshReceipts() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchReceipts());
  }

  Future<void> addReceipt(ReceiptModel receipt) async {
    _localReceipts.insert(0, receipt);
    state = AsyncData(List.from(_localReceipts));

    if (_supabase != null) {
      try {
        await _supabase!.from('receipts').insert(receipt.toJson());
      } catch (e) {
        // Kept in local state
      }
    }

    // Automatically deduct stock for new sale items
    await ref.read(inventoryProvider.notifier).adjustStockForReceiptEdit(
      oldItems: [],
      newItems: receipt.items,
    );
  }

  Future<void> updateReceipt(ReceiptModel receipt) async {
    final index = _localReceipts.indexWhere((r) => r.id == receipt.id);
    ReceiptModel? oldReceipt;
    if (index != -1) {
      oldReceipt = _localReceipts[index];
      _localReceipts[index] = receipt;
      state = AsyncData(List.from(_localReceipts));
    }

    if (_supabase != null) {
      try {
        await _supabase!
            .from('receipts')
            .update(receipt.toJson())
            .eq('id', receipt.id);
      } catch (e) {
        // Kept in local state
      }
    }

    // Automatically adjust stock if items changed during edit
    if (oldReceipt != null) {
      await ref.read(inventoryProvider.notifier).adjustStockForReceiptEdit(
        oldItems: oldReceipt.items,
        newItems: receipt.items,
      );
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    final index = _localReceipts.indexWhere((r) => r.id == receiptId);
    ReceiptModel? oldReceipt;
    if (index != -1) {
      oldReceipt = _localReceipts.removeAt(index);
      state = AsyncData(List.from(_localReceipts));
    }

    if (_supabase != null) {
      try {
        await _supabase!.from('receipts').delete().eq('id', receiptId);
      } catch (e) {
        // Kept in local state
      }
    }

    if (oldReceipt != null) {
      await ref.read(inventoryProvider.notifier).adjustStockForReceiptEdit(
        oldItems: oldReceipt.items,
        newItems: [],
      );
    }
  }
}
