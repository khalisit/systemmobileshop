import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repair_receipt_model.dart';
import '../core/config/supabase_config.dart';

final repairReceiptsProvider =
    AsyncNotifierProvider<RepairReceiptsNotifier, List<RepairReceiptModel>>(() {
  return RepairReceiptsNotifier();
});

class RepairReceiptsNotifier extends AsyncNotifier<List<RepairReceiptModel>> {
  final List<RepairReceiptModel> _localReceipts = [];

  SupabaseClient? get _supabase =>
      SupabaseConfig.isConfigured() ? Supabase.instance.client : null;

  @override
  Future<List<RepairReceiptModel>> build() async {
    return _fetchReceipts();
  }

  Future<List<RepairReceiptModel>> _fetchReceipts() async {
    if (_supabase == null) return _localReceipts;

    try {
      final response = await _supabase!
          .from('repair_receipts')
          .select()
          .order('date', ascending: false);
      final list =
          (response as List).map((e) => RepairReceiptModel.fromJson(e)).toList();
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

  Future<void> addReceipt(RepairReceiptModel receipt) async {
    _localReceipts.insert(0, receipt);
    state = AsyncData(List.from(_localReceipts));

    if (_supabase != null) {
      try {
        await _supabase!.from('repair_receipts').insert(receipt.toJson());
      } catch (e) {
        // Kept in local state
      }
    }
  }

  Future<void> updateReceipt(RepairReceiptModel receipt) async {
    final index = _localReceipts.indexWhere((r) => r.id == receipt.id);
    if (index != -1) {
      _localReceipts[index] = receipt;
      state = AsyncData(List.from(_localReceipts));
    }

    if (_supabase != null) {
      try {
        await _supabase!
            .from('repair_receipts')
            .update(receipt.toJson())
            .eq('id', receipt.id);
      } catch (e) {
        // Kept in local state
      }
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    final index = _localReceipts.indexWhere((r) => r.id == receiptId);
    if (index != -1) {
      _localReceipts.removeAt(index);
      state = AsyncData(List.from(_localReceipts));
    }

    if (_supabase != null) {
      try {
        await _supabase!.from('repair_receipts').delete().eq('id', receiptId);
      } catch (e) {
        // Kept in local state
      }
    }
  }
}
