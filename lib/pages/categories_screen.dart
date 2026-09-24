import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';
import '../providers/auth_provider.dart';
import '../models/category_model.dart';
import '../core/utils/english_digits_formatter.dart';
import '../providers/category_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.category_rounded,
                color: Color(0xFFEC4899),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'بەڕێوەبردنی جۆری بەرهەمەکان (Categories)',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'نوێکردنەوە لە Supabase',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () {
              ref.read(categoryProvider.notifier).refreshCategories();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'زیادکردنی جۆر',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _showCategoryDialog(context, ref),
            ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => _buildContent(isLoading: true, categories: []),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'کێشەیەک ڕوویدا: $err',
                style: const TextStyle(fontFamily: 'Rabar', color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(categoryProvider.notifier).refreshCategories(),
                child: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar')),
              ),
            ],
          ),
        ),
        data: (allCategories) => _buildContent(isLoading: false, categories: allCategories),
      ),
    );
  }

  Widget _buildContent({required bool isLoading, required List<CategoryModel> categories}) {
    final searchQuery = _searchCtrl.text.trim().toLowerCase();
    final filteredCategories = categories.where((c) {
      return searchQuery.isEmpty || c.name.toLowerCase().contains(searchQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.category_rounded, color: Color(0xFFEC4899), size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'کۆی سەرجەم جۆرەکان (Categories)',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isLoading
                        ? Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          )
                            .animate(onPlay: (c) => c.repeat())
                            .shimmer(duration: 1200.ms, color: Colors.white24)
                        : Text(
                            '${categories.length} جۆر',
                            style: const TextStyle(
                              fontFamily: 'NRT',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceColor),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: 'Rabar', color: Colors.white),
              decoration: InputDecoration(
                hintText: 'گەڕان بەدوای ناوی جۆردا...',
                hintStyle: const TextStyle(fontFamily: 'Rabar', color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.darkBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 32,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.darkBg),
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        headingTextStyle: const TextStyle(
                          fontFamily: 'Rabar',
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        dataTextStyle: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        columns: const [
                          DataColumn(label: Text('#'), numeric: true),
                          DataColumn(label: Text('ناوی جۆر (Category Name)')),
                          DataColumn(label: Text('کردارەکان')),
                        ],
                        rows: isLoading
                            ? List.generate(4, (_) => _buildShimmerRow())
                            : filteredCategories
                                .asMap()
                                .entries
                                .map((entry) => _buildCategoryRow(entry.key, entry.value))
                                .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.03);
  }

  DataRow _buildShimmerRow() {
    return DataRow(
      cells: List.generate(
        3,
        (index) => DataCell(
          Container(
            width: index == 0 ? 180 : (index == 1 ? 100 : 70),
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white24),
        ),
      ),
    );
  }

  DataRow _buildCategoryRow(int index, CategoryModel cat) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            '${index + 1}',
            style: const TextStyle(
              fontFamily: 'NRT',
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.label_rounded, color: Color(0xFFEC4899), size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                cat.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                tooltip: 'ئیدیت',
                onPressed: () => _showCategoryDialog(context, ref, existingCategory: cat),
              ),
              if (!ref.watch(authProvider).isCashier)
                IconButton(
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  tooltip: 'سڕینەوە',
                  onPressed: () => _confirmDelete(context, ref, cat),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    CategoryModel? existingCategory,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryFormDialog(existingCategory: existingCategory),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'دڵنیایت لە سڕینەوە؟',
          style: TextStyle(fontFamily: 'Rabar', color: Colors.white),
        ),
        content: Text(
          'ئایا دڵنیایت لە سڕینەوەی جۆری (${cat.name})؟',
          style: const TextStyle(fontFamily: 'Rabar', color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'نەخێر',
              style: TextStyle(fontFamily: 'Rabar', color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(categoryProvider.notifier).deleteCategory(cat.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'بەڵێ، بیسڕەوە',
              style: TextStyle(fontFamily: 'Rabar'),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryFormDialog extends ConsumerStatefulWidget {
  final CategoryModel? existingCategory;
  const CategoryFormDialog({super.key, this.existingCategory});

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingCategory?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final cat = CategoryModel(
        id: widget.existingCategory?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
      );

      try {
        if (widget.existingCategory != null) {
          await ref.read(categoryProvider.notifier).updateCategory(cat);
        } else {
          await ref.read(categoryProvider.notifier).addCategory(cat);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            'کێشەیەک هەیە لە داتابەیسی Supabase: $e',
            type: ToastType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceColor),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.category_rounded,
                      color: Color(0xFFEC4899),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.existingCategory != null
                          ? 'دەستکاریکردنی جۆر'
                          : 'زیادکردنی جۆری نوێ',
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: TextFormField(
                  controller: _nameCtrl,
                  inputFormatters: const [EnglishDigitsTextInputFormatter()],
                  style: const TextStyle(fontFamily: 'Rabar', color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'ناوی جۆر (مثلاً: موبایل، کەل و پەل...)',
                    labelStyle: const TextStyle(fontFamily: 'Rabar', color: Colors.white54),
                    prefixIcon: const Icon(Icons.label_rounded, color: Colors.white24, size: 20),
                    filled: true,
                    fillColor: AppTheme.darkBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'پێویستە ناوی جۆر پڕبکرێتەوە';
                    return null;
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'پاشگەزبونەوە',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _save,
                      child: Text(
                        widget.existingCategory != null ? 'هەڵگرتن' : 'زیادکردن',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
