import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repair_type_model.dart';
import '../core/config/supabase_config.dart';

final repairTypesProvider =
    AsyncNotifierProvider<RepairTypesNotifier, List<RepairTypeModel>>(() {
      return RepairTypesNotifier();
    });

class RepairTypesNotifier extends AsyncNotifier<List<RepairTypeModel>> {
  SupabaseClient? get _supabase =>
      SupabaseConfig.isConfigured() ? Supabase.instance.client : null;

  @override
  Future<List<RepairTypeModel>> build() async {
    return _fetchRepairTypes();
  }

  Future<List<RepairTypeModel>> _fetchRepairTypes() async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    final response =
        await _supabase!.from('repair_types').select().order('name', ascending: true);
    final list =
        (response as List).map((e) => RepairTypeModel.fromJson(e)).toList();
    return list;
  }

  Future<void> refreshRepairTypes() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchRepairTypes());
  }

  Future<void> addRepairType(RepairTypeModel type) async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    state = const AsyncLoading();
    try {
      await _supabase!.from('repair_types').insert(type.toJson());
      final updatedList = await _fetchRepairTypes();
      state = AsyncData(updatedList);
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchRepairTypes());
      rethrow;
    }
  }

  Future<void> updateRepairType(RepairTypeModel type) async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    state = const AsyncLoading();
    try {
      await _supabase!
          .from('repair_types')
          .update(type.toJson())
          .eq('id', type.id);
      final updatedList = await _fetchRepairTypes();
      state = AsyncData(updatedList);
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchRepairTypes());
      rethrow;
    }
  }

  Future<void> deleteRepairType(String id) async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    state = const AsyncLoading();
    try {
      await _supabase!.from('repair_types').delete().eq('id', id);
      final updatedList = await _fetchRepairTypes();
      state = AsyncData(updatedList);
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchRepairTypes());
      rethrow;
    }
  }
}
