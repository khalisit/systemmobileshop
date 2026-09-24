import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../core/config/supabase_config.dart';

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>>(() {
      return CategoryNotifier();
    });

class CategoryNotifier extends AsyncNotifier<List<CategoryModel>> {
  SupabaseClient? get _supabase =>
      SupabaseConfig.isConfigured() ? Supabase.instance.client : null;

  @override
  Future<List<CategoryModel>> build() async {
    return _fetchCategories();
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    final response =
        await _supabase!.from('categories').select().order('name', ascending: true);
    final list =
        (response as List).map((e) => CategoryModel.fromJson(e)).toList();
    return list;
  }

  Future<void> refreshCategories() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchCategories());
  }

  Future<void> addCategory(CategoryModel category) async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    state = const AsyncLoading();
    try {
      await _supabase!.from('categories').insert(category.toJson());
      final updatedList = await _fetchCategories();
      state = AsyncData(updatedList);
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchCategories());
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    state = const AsyncLoading();
    try {
      await _supabase!
          .from('categories')
          .update(category.toJson())
          .eq('id', category.id);
      final updatedList = await _fetchCategories();
      state = AsyncData(updatedList);
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchCategories());
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    if (_supabase == null) {
      throw Exception('Supabase دامەنەزراوە');
    }

    state = const AsyncLoading();
    try {
      await _supabase!.from('categories').delete().eq('id', id);
      final updatedList = await _fetchCategories();
      state = AsyncData(updatedList);
    } catch (e) {
      state = await AsyncValue.guard(() => _fetchCategories());
      rethrow;
    }
  }
}
