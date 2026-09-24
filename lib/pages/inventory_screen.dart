import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../core/utils/english_digits_formatter.dart';
import '../providers/category_provider.dart';
import 'categories_screen.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'کشت'; // All
  final List<String> _scanBuffer = [];
  DateTime? _lastCharTime;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final authState = ref.watch(authProvider);
    final isCashier = authState.isCashier;

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          final now = DateTime.now();
          final char = event.character;

          if (_lastCharTime != null &&
              now.difference(_lastCharTime!) >
                  const Duration(milliseconds: 65)) {
            _scanBuffer.clear();
          }
          _lastCharTime = now;

          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (_scanBuffer.isNotEmpty) {
              final barcode = _scanBuffer.join().trim();
              if (barcode.isNotEmpty) {
                setState(() {
                  _searchCtrl.text = barcode;
                });
                AppToast.show(
                  context,
                  'گەڕان بەپێی بارکۆد: $barcode',
                  type: ToastType.success,
                );
              }
              _scanBuffer.clear();
            }
          } else if (char != null &&
              char.isNotEmpty &&
              RegExp(r'[a-zA-Z0-9\-_]').hasMatch(char)) {
            _scanBuffer.add(char);
          }
        }
      },
      child: Scaffold(
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'بەڕێوەبردنی کۆگا ',
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
              tooltip: 'نوێکردنەوە ',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: () {
                ref.read(inventoryProvider.notifier).refreshProducts();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'زیادکردنی بەرهەم',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _showProductDialog(context, ref),
              ),
            ),
          ],
        ),
        body: inventoryAsync.when(
          loading: () => _buildContent(
            isLoading: true,
            products: [],
            categories: [],
            isCashier: isCashier,
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  'کێشەیەک ڕوویدا لە هێنانی زانیاری: $err',
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(inventoryProvider.notifier).refreshProducts(),
                  child: const Text(
                    'دووبارە هەوڵبدەرەوە',
                    style: TextStyle(fontFamily: 'Rabar'),
                  ),
                ),
              ],
            ),
          ),
          data: (allProducts) {
            final categoriesList = categoriesAsync.maybeWhen(
              data: (cats) => cats,
              orElse: () => <CategoryModel>[],
            );
            return _buildContent(
              isLoading: false,
              products: allProducts,
              categories: categoriesList,
              isCashier: isCashier,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent({
    required bool isLoading,
    required List<Product> products,
    required List<CategoryModel> categories,
    required bool isCashier,
  }) {
    final searchQuery = _searchCtrl.text.trim().toLowerCase();
    final filteredProducts = products.where((p) {
      final matchesSearch =
          searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery) ||
          p.sku.toLowerCase().contains(searchQuery);
      final matchesCategory =
          _selectedCategory == 'کشت' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final totalStock = products.fold<int>(0, (sum, p) => sum + p.stock);
    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + (p.buyPrice * p.stock),
    );
    final lowStockCount = products.where((p) => p.stock <= 3).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildSummaryCard(
                title: 'کۆی بەرهەمەکان',
                value: isLoading ? '...' : '${products.length} بەرهەم',
                icon: Icons.inventory_2_rounded,
                color: AppTheme.primaryColor,
                isLoading: isLoading,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                title: 'کۆی بەردەست (دانە)',
                value: isLoading ? '...' : '$totalStock دانە',
                icon: Icons.inventory_rounded,
                color: const Color(0xFF10B981),
                isLoading: isLoading,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                title: 'بەهای کۆی بەردەست',
                value: isLoading ? '...' : '\$${totalValue.toStringAsFixed(2)}',
                icon: Icons.attach_money_rounded,
                color: const Color(0xFFF59E0B),
                isLoading: isLoading,
              ),
              const SizedBox(width: 12),
              _buildSummaryCard(
                title: 'کەمی بەرهەم ',
                value: isLoading ? '...' : '$lowStockCount بەرهەم',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEF4444),
                isLoading: isLoading,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceColor),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    inputFormatters: const [EnglishDigitsTextInputFormatter()],
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'گەڕان بەدوای ناوی بەرهەم یان بارکۆد/SKU...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Rabar',
                        color: Colors.white38,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white38,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Colors.white38,
                              ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value:
                        categories.any((c) => c.name == _selectedCategory) ||
                            _selectedCategory == 'کشت'
                        ? _selectedCategory
                        : 'کشت',
                    dropdownColor: AppTheme.cardBg,
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      color: Colors.white,
                    ),
                    icon: const Icon(
                      Icons.filter_list_rounded,
                      color: Colors.white70,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'کشت',
                        child: Text('هەموو جۆرەکان (All)'),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
              ),
            ],
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
                        headingRowColor: WidgetStateProperty.all(
                          AppTheme.darkBg,
                        ),
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
                        columns: [
                          const DataColumn(label: Text('#'), numeric: true),
                          const DataColumn(label: Text('ناوی بەرهەم')),
                          const DataColumn(label: Text('کاتیگۆری')),
                          const DataColumn(label: Text('بارکۆد/SKU')),
                          const DataColumn(
                            label: Text('کڕین (\$)'),
                            numeric: true,
                          ),
                          if (!isCashier)
                            const DataColumn(
                              label: Text('فرۆشتن (\$)'),
                              numeric: true,
                            ),
                          const DataColumn(
                            label: Text('مەخزەن'),
                            numeric: true,
                          ),
                          const DataColumn(label: Text('کردارەکان')),
                        ],
                        rows: isLoading
                            ? List.generate(
                                5,
                                (_) => _buildShimmerRow(isCashier: isCashier),
                              )
                            : filteredProducts
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => _buildProductRow(
                                      entry.key,
                                      entry.value,
                                      isCashier: isCashier,
                                    ),
                                  )
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

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    return Expanded(
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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? Container(
                            width: 70,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 1200.ms, color: Colors.white24)
                    : Text(
                        value,
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
    );
  }

  DataRow _buildShimmerRow({bool isCashier = false}) {
    final colCount = isCashier ? 7 : 8;
    return DataRow(
      cells: List.generate(
        colCount,
        (index) => DataCell(
          Container(
                width: index == 1 ? 140 : (index == (colCount - 1) ? 60 : 40),
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

  DataRow _buildProductRow(int index, Product p, {bool isCashier = false}) {
    final isLowStock = p.stock <= 3;

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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.phone_iphone_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                p.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              p.category,
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 11,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            p.sku,
            style: const TextStyle(fontFamily: 'NRT', color: Colors.white70),
          ),
        ),
        DataCell(
          Text(
            '\$${p.buyPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontFamily: 'NRT', color: Colors.white70),
          ),
        ),
        if (!isCashier)
          DataCell(
            Text(
              '\$${p.sellPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'NRT',
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLowStock
                  ? Colors.redAccent.withValues(alpha: 0.15)
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isLowStock
                    ? Colors.redAccent.withValues(alpha: 0.3)
                    : const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${p.stock} دانە',
              style: TextStyle(
                fontFamily: 'NRT',
                fontWeight: FontWeight.bold,
                color: isLowStock ? Colors.redAccent : const Color(0xFF10B981),
              ),
            ),
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
                onPressed: () =>
                    _showProductDialog(context, ref, existingProduct: p),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                tooltip: 'سڕینەوە',
                onPressed: () => _confirmDelete(context, ref, p),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProductDialog(
    BuildContext context,
    WidgetRef ref, {
    Product? existingProduct,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ProductFormDialog(existingProduct: existingProduct),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product p) {
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
          'ئایا دڵنیایت لە سڕینەوەی بەرهەمی (${p.name})؟',
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
              await ref.read(inventoryProvider.notifier).deleteProduct(p.id);
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

class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? existingProduct;
  const ProductFormDialog({super.key, this.existingProduct});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _buyPriceCtrl;
  late TextEditingController _sellPriceCtrl;
  late TextEditingController _stockCtrl;
  String? _category;
  final List<String> _scanBuffer = [];
  DateTime? _lastCharTime;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _skuCtrl = TextEditingController(
      text:
          p?.sku ??
          'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    _buyPriceCtrl = TextEditingController(text: p?.buyPrice.toString() ?? '');
    _sellPriceCtrl = TextEditingController(text: p?.sellPrice.toString() ?? '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '1');
    _category = p?.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final p = Product(
        id: widget.existingProduct?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        category: _category ?? 'موبایل / Phones',
        sku: _skuCtrl.text.trim(),
        buyPrice: double.tryParse(_buyPriceCtrl.text.trim()) ?? 0,
        sellPrice: double.tryParse(_sellPriceCtrl.text.trim()) ?? 0,
        stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      );

      try {
        if (widget.existingProduct != null) {
          await ref.read(inventoryProvider.notifier).updateProduct(p);
        } else {
          await ref.read(inventoryProvider.notifier).addProduct(p);
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
    final categoriesAsync = ref.watch(categoryProvider);
    final availableCategories = categoriesAsync.maybeWhen(
      data: (cats) => cats,
      orElse: () => <CategoryModel>[],
    );

    if (_category == null && availableCategories.isNotEmpty) {
      _category = availableCategories.first.name;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            final now = DateTime.now();
            final char = event.character;

            if (_lastCharTime != null &&
                now.difference(_lastCharTime!) >
                    const Duration(milliseconds: 65)) {
              _scanBuffer.clear();
            }
            _lastCharTime = now;

            if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (_scanBuffer.isNotEmpty) {
                final barcode = _scanBuffer.join().trim();
                if (barcode.isNotEmpty) {
                  setState(() {
                    _skuCtrl.text = barcode;
                  });
                  AppToast.show(
                    context,
                    'بارکۆد سکان کرا: $barcode',
                    type: ToastType.success,
                  );
                }
                _scanBuffer.clear();
              }
            } else if (char != null &&
                char.isNotEmpty &&
                RegExp(r'[a-zA-Z0-9\-_]').hasMatch(char)) {
              _scanBuffer.add(char);
            }
          }
        },
        child: Container(
          width: 550,
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(19),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.existingProduct != null
                            ? 'دەستکاریکردنی بەرهەم'
                            : 'زیادکردنی بەرهەمی نوێ',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          inputFormatters: const [
                            EnglishDigitsTextInputFormatter(),
                          ],
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white,
                          ),
                          decoration: _buildInputDeco(
                            'ناوی بەرهەم',
                            Icons.shopping_bag_rounded,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'پێویستە ناوی بەرهەم پڕبکرێتەوە'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _category,
                                dropdownColor: AppTheme.cardBg,
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  color: Colors.white,
                                ),
                                decoration: _buildInputDeco(
                                  'کاتیگۆری',
                                  Icons.category_rounded,
                                ),
                                items: availableCategories.isNotEmpty
                                    ? availableCategories
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c.name,
                                              child: Text(c.name),
                                            ),
                                          )
                                          .toList()
                                    : ProductCategory.values
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c.displayName,
                                              child: Text(c.displayName),
                                            ),
                                          )
                                          .toList(),
                                onChanged: (val) =>
                                    setState(() => _category = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppTheme.primaryColor,
                              ),
                              tooltip: 'زیادکردنی کاتیگۆریی نوێ',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const CategoryFormDialog(),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _skuCtrl,
                                autofocus: widget.existingProduct == null,
                                inputFormatters: const [
                                  EnglishDigitsTextInputFormatter(),
                                ],
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  color: Colors.white,
                                ),
                                decoration:
                                    _buildInputDeco(
                                      'بارکۆد / SKU (سکان بکە یان بنووسە)',
                                      Icons.qr_code_rounded,
                                    ).copyWith(
                                      suffixIcon: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Icon(
                                          Icons.usb_rounded,
                                          color: Color(0xFF10B981),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'پێویستە بارکۆد پڕبکرێتەوە'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _buyPriceCtrl,
                                inputFormatters: const [
                                  EnglishDigitsTextInputFormatter(),
                                ],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  color: Colors.white,
                                ),
                                decoration: _buildInputDeco(
                                  'نرخی کڕین (\$)',
                                  Icons.download_rounded,
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'پێویستە پڕبکرێتەوە'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _sellPriceCtrl,
                                inputFormatters: const [
                                  EnglishDigitsTextInputFormatter(),
                                ],
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  color: Colors.white,
                                ),
                                decoration: _buildInputDeco(
                                  'نرخی فرۆشتن (\$)',
                                  Icons.upload_rounded,
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'پێویستە پڕبکرێتەوە'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _stockCtrl,
                          inputFormatters: const [
                            EnglishDigitsTextInputFormatter(),
                          ],
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Colors.white,
                          ),
                          decoration: _buildInputDeco(
                            'بڕی بەردەست (Stock)',
                            Icons.inventory_rounded,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'پێویستە بڕی بەردەست بنووسرێت'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.darkBg,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(19),
                    ),
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
                          backgroundColor: AppTheme.primaryColor,
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
                          widget.existingProduct != null
                              ? 'هەڵگرتن'
                              : 'زیادکردن',
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
      ),
    );
  }

  InputDecoration _buildInputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Rabar', color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white24, size: 20),
      filled: true,
      fillColor: AppTheme.darkBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
