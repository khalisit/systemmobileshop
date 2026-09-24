import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/receipt_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_toast.dart';
import '../core/utils/english_digits_formatter.dart';
import '../models/cart_item.dart';
import '../providers/pos_provider.dart';
import '../providers/receipts_provider.dart';
import '../providers/category_provider.dart';
import '../providers/inventory_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _custNameCtrl = TextEditingController();
  final TextEditingController _custPhoneCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();
  final TextEditingController _paidAmountCtrl = TextEditingController();
  final ScrollController _categoryScrollCtrl = ScrollController();
  final List<String> _scanBuffer = [];
  DateTime? _lastCharTime;
  bool _scannerPaused = false;
  Timer? _scanPauseTimer;

  @override
  void initState() {
    super.initState();
    _syncFormWithState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void _syncFormWithState() {
    final posState = ref.read(posProvider);
    _custNameCtrl.text = posState.customerName;
    _custPhoneCtrl.text = posState.customerPhone;
    _discountCtrl.text = posState.discount > 0
        ? posState.discount.toString()
        : '';
    if (posState.paidAmount != null) {
      _paidAmountCtrl.text = posState.paidAmount!.toString();
    } else {
      _paidAmountCtrl.text = '';
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _scanPauseTimer?.cancel();
    _searchCtrl.dispose();
    _custNameCtrl.dispose();
    _custPhoneCtrl.dispose();
    _discountCtrl.dispose();
    _paidAmountCtrl.dispose();
    _categoryScrollCtrl.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_scannerPaused) return false;
      final now = DateTime.now();
      final char = event.character;

      if (_lastCharTime != null &&
          now.difference(_lastCharTime!) > const Duration(milliseconds: 65)) {
        _scanBuffer.clear();
      }
      _lastCharTime = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_scanBuffer.isNotEmpty) {
          final barcode = _scanBuffer.join().trim();
          if (barcode.isNotEmpty) {
            final posState = ref.read(posProvider);
            final products = ref.read(inventoryProvider).value ?? [];
            final matchIndex = products.indexWhere(
              (p) => p.sku.toLowerCase() == barcode.toLowerCase(),
            );
            if (matchIndex != -1) {
              final product = products[matchIndex];
              final cartIndex = posState.cart.indexWhere(
                (item) => item.product.id == product.id,
              );
              final currentQty = cartIndex >= 0
                  ? posState.cart[cartIndex].quantity
                  : 0;

              if (product.stock > currentQty) {
                ref.read(posProvider.notifier).addToCart(product);
                AppToast.show(
                  context,
                  'کاڵای "${product.name}" زیادکرا بۆ سەبەتە',
                  type: ToastType.success,
                );
              } else {
                AppToast.show(
                  context,
                  'بڕی بەردەست لە کۆگا بەشی ناکات! (بەردەست: ${product.stock})',
                  type: ToastType.error,
                );
              }
            } else {
              AppToast.show(
                context,
                'ئەم باڕکۆدە بوونی نییە لە کۆگادا: $barcode',
                type: ToastType.error,
              );
            }
          }
          _scanBuffer.clear();
          // ٢ چرکە بوەستێت پاش سکان کردن
          _scannerPaused = true;
          _scanPauseTimer?.cancel();
          _scanPauseTimer = Timer(const Duration(seconds: 1), () {
            if (mounted) setState(() => _scannerPaused = false);
          });
          return true; // Prevent enter from triggering other things
        }
      } else if (char != null &&
          char.isNotEmpty &&
          RegExp(r'[a-zA-Z0-9\-_]').hasMatch(char)) {
        _scanBuffer.add(char);
        // If the buffer is growing quickly, it's likely a scan, we could return true to prevent text fields from getting it
        // but it's tricky. Let's just return false to not break text inputs.
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posProvider);
    final isEditing = posState.editingReceiptId != null;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1A2E),
        elevation: 0,
        leadingWidth: 110,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isEditing ? Colors.orange : AppTheme.accentColor)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isEditing ? Icons.edit_note_rounded : Icons.store_rounded,
                color: isEditing ? Colors.orange : AppTheme.accentColor,
                size: 20,
              ),
            ),
          ],
        ),
        title: Text(
          isEditing
              ? 'دەستکاریکردنی وەسڵ #${posState.editingReceiptId!.substring(0, 8)}'
              : 'فرۆشتنی نوێ',
          style: const TextStyle(
            fontFamily: 'Rabar',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  ref.read(posProvider.notifier).clear();
                  _syncFormWithState();
                },
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: const Text(
                  'پاشگەزبوونەوە لە دەستکاری',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),

          // Clear cart red button
          IconButton(
            onPressed: () {
              ref.read(posProvider.notifier).clearCart();
            },
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
            tooltip: 'بەتاڵکردنی سەبەتە',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Right: Products Grid (larger flex) - First child in RTL
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _buildSearchAndFilterBar(),
                Expanded(child: _buildProductsGrid()),
              ],
            ),
          ),
          Container(width: 1, color: AppTheme.surfaceColor),
          // Left: Shopping Cart (smaller flex) - Last child in RTL
          Expanded(flex: 2, child: _buildCartPanel()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final posState = ref.watch(posProvider);
    final categoriesAsync = ref.watch(categoryProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.darkBg,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: TextField(
                controller: _searchCtrl,
                inputFormatters: const [EnglishDigitsTextInputFormatter()],
                onChanged: (val) =>
                    ref.read(posProvider.notifier).setSearchQuery(val),
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  color: Colors.white,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'گەڕان بە ناو یان SKU...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Colors.white38,
                            size: 16,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(posProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          categoriesAsync.maybeWhen(
            data: (categories) {
              return Align(
                alignment: Alignment.centerRight,
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _categoryScrollCtrl.animateTo(
                        (_categoryScrollCtrl.offset + event.scrollDelta.dy)
                            .clamp(
                              0.0,
                              _categoryScrollCtrl.position.maxScrollExtent,
                            ),
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Scrollbar(
                    controller: _categoryScrollCtrl,
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _categoryScrollCtrl,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildCategoryChip(
                              label: 'هەموو',
                              isSelected: posState.filterCategory == null,
                              onTap: () => ref
                                  .read(posProvider.notifier)
                                  .setFilter(null),
                            ),
                            ...categories.map(
                              (cat) => _buildCategoryChip(
                                label: cat.name,
                                isSelected: posState.filterCategory == cat.name,
                                onTap: () => ref
                                    .read(posProvider.notifier)
                                    .setFilter(cat.name),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData chipIcon = Icons.category_rounded;
    if (label == 'هەموو') {
      chipIcon = Icons.grid_view_rounded;
    } else {
      chipIcon = Icons.devices_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0EA5E9).withValues(alpha: 0.1)
                : const Color(0xFF334155),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFF334155),
              width: isSelected ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                chipIcon,
                size: 14,
                color: isSelected ? const Color(0xFF0EA5E9) : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11,
                  color: isSelected ? const Color(0xFF0EA5E9) : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    final posState = ref.watch(posProvider);
    final productsAsync = ref.watch(filteredProductsProvider);

    return productsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accentColor),
      ),
      error: (e, _) => Center(
        child: Text(
          'هەڵەیەک ڕوویدا: $e',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Text(
              'هیچ بەرهەمێک نەدۆزرایەوە',
              style: TextStyle(fontFamily: 'Rabar', color: Colors.white38),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 155,
            childAspectRatio: 1.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (ctx, idx) {
            final product = products[idx];
            final cartIndex = posState.cart.indexWhere(
              (c) => c.product.id == product.id,
            );
            final cartQty = cartIndex >= 0
                ? posState.cart[cartIndex].quantity
                : 0;
            final isInCart = cartQty > 0;

            return GestureDetector(
              onTap: () {
                if (product.stock > 0) {
                  ref.read(posProvider.notifier).addToCart(product);
                } else {
                  AppToast.show(
                    context,
                    'ئەم کاڵایە لە کۆگادا نەماوە!',
                    type: ToastType.error,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8), // Thinner padding
                decoration: BoxDecoration(
                  color: isInCart ? const Color(0x4B10B981) : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInCart
                        ? const Color(0xFF10B981)
                        : AppTheme.surfaceColor,
                    width: isInCart ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 18,
                          color: isInCart
                              ? const Color(0xFF10B981)
                              : Colors.white30,
                        ),
                        isInCart
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${cartQty}x',
                                  style: const TextStyle(
                                    fontFamily: 'NRT',
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        product.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 11, // Smaller font
                          height: 1.2,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.sellPrice.toStringAsFixed(product.sellPrice % 1 == 0 ? 0 : 2)}',
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${product.stock} ماوە',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11,
                            color: product.stock > 0
                                ? Colors.white54
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(),
            );
          },
        );
      },
    );
  }

  Widget _buildCartPanel() {
    final posState = ref.watch(posProvider);
    final isEditing = posState.editingReceiptId != null;

    return Container(
      color: AppTheme.darkBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: AppTheme.cardBg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_cart_rounded,
                      color: AppTheme.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'سەبەتەی کڕین',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                Text(
                  '${posState.itemCount} دانه',
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: posState.cart.isEmpty
                ? const Center(
                    child: Text(
                      'سەبەتە بەتاڵە\nتکایە کاڵا هەڵبژێرە',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: posState.cart.length,
                    itemBuilder: (ctx, idx) {
                      final item = posState.cart[idx];
                      return _buildCartItemTile(item);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.darkBg,
              border: Border(top: BorderSide(color: AppTheme.surfaceColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'زانیاری کڕیار (ئۆپشناڵ)',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _custNameCtrl,
                          inputFormatters: const [
                            EnglishDigitsTextInputFormatter(),
                          ],
                          onChanged: (v) =>
                              ref.read(posProvider.notifier).setCustomerName(v),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: _buildMiniInputDeco(
                            'ناوی کڕیار',
                            Icons.person_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _custPhoneCtrl,
                          inputFormatters: const [
                            EnglishDigitsTextInputFormatter(),
                          ],
                          onChanged: (v) => ref
                              .read(posProvider.notifier)
                              .setCustomerPhone(v),
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: _buildMiniInputDeco(
                            'ژمارەی تەلەفۆن',
                            Icons.phone_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Discount row
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountCtrl,
                          inputFormatters: const [
                            EnglishDigitsTextInputFormatter(),
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final d = double.tryParse(v) ?? 0.0;
                            ref.read(posProvider.notifier).setDiscount(d);
                          },
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: _buildMiniInputDeco(
                            'بڕی داشکاندن',
                            Icons.local_offer_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.surfaceColor),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => ref
                                    .read(posProvider.notifier)
                                    .setDiscountType('percent'),
                                child: Container(
                                  width: 32,
                                  height: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: posState.discountType == 'percent'
                                        ? const Color(0xFF10B981)
                                        : AppTheme.cardBg,
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(7),
                                    ),
                                  ),
                                  child: Text(
                                    '%',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontWeight: FontWeight.bold,
                                      color: posState.discountType == 'percent'
                                          ? Colors.white
                                          : Colors.white60,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 2,
                                color: AppTheme.surfaceColor,
                                height: double.infinity,
                              ),
                              GestureDetector(
                                onTap: () => ref
                                    .read(posProvider.notifier)
                                    .setDiscountType('amount'),
                                child: Container(
                                  width: 32,
                                  height: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: posState.discountType == 'amount'
                                        ? const Color(0xFF10B981)
                                        : AppTheme.cardBg,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(7),
                                    ),
                                  ),
                                  child: Text(
                                    '\$',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontWeight: FontWeight.bold,
                                      color: posState.discountType == 'amount'
                                          ? Colors.white
                                          : Colors.white60,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'شێوازی پارەدان',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(posProvider.notifier)
                                .setPaymentMethod('نەقد');
                            _paidAmountCtrl.clear();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: posState.paymentMethod == 'نەقد'
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.3)
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: posState.paymentMethod == 'نەقد'
                                    ? const Color(0xFF10B981)
                                    : AppTheme.surfaceColor,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              'نەقد',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontWeight: FontWeight.bold,
                                color: posState.paymentMethod == 'نەقد'
                                    ? const Color(0xFF10B981)
                                    : Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(posProvider.notifier)
                                .setPaymentMethod('قەرز');
                            _paidAmountCtrl.clear();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: posState.paymentMethod == 'قەرز'
                                  ? const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.3)
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: posState.paymentMethod == 'قەرز'
                                    ? const Color(0xFFF59E0B)
                                    : AppTheme.surfaceColor,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              'قەرز',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontWeight: FontWeight.bold,
                                color: posState.paymentMethod == 'قەرز'
                                    ? const Color(0xFFF59E0B)
                                    : Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      if (posState.paymentMethod == 'قەرز') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppTheme.cardBg,
                            border: Border.all(
                              width: 1,
                              color: AppTheme.surfaceColor,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 2,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'قەرزی ماوە',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 9,
                                  color: Colors.white54,
                                ),
                              ),
                              Text(
                                '\$${posState.remainingDebt.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'NRT',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: TextField(
                          controller: _paidAmountCtrl
                            ..text = posState.paymentMethod == 'نەقد'
                                ? posState.grandTotal.toStringAsFixed(2)
                                : (_paidAmountCtrl.text.isEmpty
                                      ? ''
                                      : _paidAmountCtrl.text),
                          readOnly: posState.paymentMethod == 'نەقد',
                          inputFormatters: const [
                            EnglishDigitsTextInputFormatter(),
                          ],
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final val = double.tryParse(v);
                            ref.read(posProvider.notifier).setPaidAmount(val);
                          },
                          style: const TextStyle(
                            fontFamily: 'NRT',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: _buildMiniInputDeco(
                            'بڕی پێدراو',
                            Icons.payments_rounded,
                          ),
                        ),
                      ),
                      if (posState.paymentMethod == 'قەرز') ...[
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              final totalStr = posState.grandTotal
                                  .toStringAsFixed(2);
                              _paidAmountCtrl.text = totalStr;
                              ref
                                  .read(posProvider.notifier)
                                  .setPaidAmount(posState.grandTotal);
                            },
                            child: const Text(
                              'کۆیی',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: AppTheme.surfaceColor, height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(color: AppTheme.cardBg),
                  child: Column(
                    children: [
                      // Totals Summary Box
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'کۆیی گشتی',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '\$${posState.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'NRT',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      if (posState.calculatedDiscount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'داشکان',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                color: Colors.redAccent,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '-\$${posState.calculatedDiscount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'NRT',
                                fontSize: 12,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'کۆی دەدرێت',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '\$${posState.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'NRT',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEditing
                          ? Colors.orange
                          : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: posState.cart.isEmpty ? null : _completeSale,
                    icon: Icon(
                      isEditing
                          ? Icons.save_rounded
                          : Icons.check_circle_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isEditing
                          ? 'پاشەکەوتکردنی دەستکاری • \$${posState.grandTotal.toStringAsFixed(2)}'
                          : 'تۆمارکردنی فرۆشتن • \$${posState.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceColor, width: 1.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_basket_outlined,
                        color: const Color(0xFF10B981),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            item.product.name,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 16,
                ),
                onPressed: () => ref
                    .read(posProvider.notifier)
                    .removeFromCart(item.product.id),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              SizedBox(
                height: 32,
                width: 160,
                child: TextField(
                  controller:
                      TextEditingController(
                          text: (item.customPrice ?? item.product.sellPrice)
                              .toString(),
                        )
                        ..selection = TextSelection.fromPosition(
                          TextPosition(
                            offset: (item.customPrice ?? item.product.sellPrice)
                                .toString()
                                .length,
                          ),
                        ),
                  inputFormatters: const [EnglishDigitsTextInputFormatter()],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontFamily: 'NRT',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintStyle: const TextStyle(
                      fontFamily: 'Rabar',
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                    filled: true,
                    fillColor: AppTheme.darkBg,
                    prefixIcon: Icon(
                      Icons.monetization_on,
                      color: Colors.white38,
                      size: 15,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.surfaceColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.surfaceColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF10B981),
                        width: 1.2,
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    final price = double.tryParse(v) ?? 0.0;
                    ref
                        .read(posProvider.notifier)
                        .updatePrice(item.product.id, price);
                  },
                ),
              ),

              const Spacer(),
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 1, color: AppTheme.surfaceColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 2),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_rounded,
                        color: Colors.red,
                        size: 14,
                      ),
                      padding: EdgeInsets.all(2),
                      constraints: const BoxConstraints(),
                      onPressed: () => ref
                          .read(posProvider.notifier)
                          .updateQuantity(item.product.id, item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontFamily: 'NRT',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF38BDF8),
                        size: 14,
                      ),
                      padding: EdgeInsets.all(2),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (item.quantity < item.product.stock) {
                          ref
                              .read(posProvider.notifier)
                              .updateQuantity(
                                item.product.id,
                                item.quantity + 1,
                              );
                        } else {
                          AppToast.show(
                            context,
                            'بڕی داواکراو زیاترە لە عەمبار!',
                            type: ToastType.error,
                          );
                        }
                      },
                    ),
                    SizedBox(width: 2),
                  ],
                ),
              ),
              SizedBox(width: 8),

              Text(
                '\$${item.total.toStringAsFixed(item.total % 1 == 0 ? 0 : 2)}',
                style: const TextStyle(
                  fontFamily: 'NRT',
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildMiniInputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Rabar',
        color: Colors.white54,
        fontSize: 11,
      ),
      filled: true,
      fillColor: AppTheme.cardBg,
      prefixIcon: Icon(icon, color: Colors.white38, size: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.surfaceColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.surfaceColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.2),
      ),
    );
  }

  void _completeSale() async {
    final posState = ref.read(posProvider);
    if (posState.cart.isEmpty) return;

    final isEditing = posState.editingReceiptId != null;

    final receipt = ReceiptModel(
      id: posState.editingReceiptId,
      customerName: posState.customerName,
      customerPhone: posState.customerPhone,
      items: posState.cart,
      discount: posState.discount,
      discountType: posState.discountType,
      grandTotal: posState.grandTotal,
      paidAmount: posState.actualPaidAmount,
      paymentMethod: posState.paymentMethod,
    );

    if (isEditing) {
      await ref.read(receiptsProvider.notifier).updateReceipt(receipt);
      if (mounted) {
        AppToast.show(
          context,
          'وەسڵەکە بە سەرکەوتوویی دەستکاری کرا!',
          type: ToastType.success,
        );
      }
    } else {
      await ref.read(receiptsProvider.notifier).addReceipt(receipt);
      if (mounted) {
        AppToast.show(
          context,
          'فرۆشتن بە سەرکەوتوویى پاشەکەوت کرا!',
          type: ToastType.success,
        );
      }
    }

    ref.read(posProvider.notifier).clear();
    _syncFormWithState();
  }
}
